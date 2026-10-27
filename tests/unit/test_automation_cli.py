#!/usr/bin/env python3
import importlib.util
import contextlib
import io
from importlib.machinery import SourceFileLoader
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
CLI_PATH = ROOT / "bin" / "elsm"
LOADER = SourceFileLoader("elsm_cli", str(CLI_PATH))
SPEC = importlib.util.spec_from_loader("elsm_cli", LOADER)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load automation CLI from {CLI_PATH}")
CLI = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CLI
SPEC.loader.exec_module(CLI)


class AutomationCliTests(unittest.TestCase):
    def test_argument_validation_requires_a_subcommand(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as error:
                CLI.parse_args([])
        self.assertEqual(error.exception.code, 2)

    def test_deploy_only_accepts_lab_profile(self):
        args = CLI.parse_args(["deploy", "--profile", "lab"])
        self.assertEqual(args.profile, "lab")
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                CLI.parse_args(["deploy", "--profile", "production"])

    def test_command_capture_records_output_exit_code_and_duration(self):
        result = CLI.run_command(
            "fixture",
            [sys.executable, "-c", "import sys; print('out'); print('err', file=sys.stderr); sys.exit(7)"],
        )
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["returncode"], 7)
        self.assertIn("out", result["stdout"])
        self.assertIn("err", result["stderr"])
        self.assertGreaterEqual(result["duration_ms"], 0)
        self.assertTrue(result["started_at"])

    def test_exit_code_distinguishes_failure_and_blocking_review(self):
        self.assertEqual(CLI.exit_for_results([CLI.check_record("a", "PASS", "")]), 0)
        self.assertEqual(CLI.exit_for_results([CLI.check_record("a", "REVIEW REQUIRED", "")]), 3)
        self.assertEqual(CLI.exit_for_results([CLI.check_record("a", "BLOCKED", "")]), 3)
        self.assertEqual(CLI.run_command("bad-exit", [sys.executable, "-c", "raise SystemExit(2)"])["status"], "FAIL")
        self.assertEqual(
            CLI.exit_for_results(
                [CLI.check_record("a", "BLOCKED", ""), CLI.check_record("b", "FAIL", "")]
            ),
            1,
        )

    def test_report_contains_counts_and_valid_json(self):
        results = [
            CLI.check_record("pass", "PASS", ""),
            CLI.check_record("skip", "NOT RUN", "optional tool unavailable"),
        ]
        report = CLI.report_payload("test", "test", results)
        encoded = json.dumps(report)
        decoded = json.loads(encoded)
        self.assertEqual(decoded["summary"]["total"], 2)
        self.assertEqual(decoded["summary"]["counts"]["PASS"], 1)
        self.assertEqual(decoded["summary"]["counts"]["NOT RUN"], 1)
        self.assertEqual(decoded["host_changes"], [])
        self.assertGreaterEqual(decoded["summary"]["duration_ms"], 0)
        self.assertTrue(decoded["recommended_next_actions"])
        self.assertIn("[NOT RUN] skip", CLI.render_text(report))

    def test_reports_are_written_with_restrictive_file_permissions(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            report_dir = directory / "reports"
            log_file = directory / "logs" / "automation.log"
            report = CLI.report_payload("test", None, [CLI.check_record("ok", "PASS", "")])
            text_path, json_path = CLI.persist_report(report, report_dir, log_file)
            self.assertEqual(json.loads(json_path.read_text(encoding="utf-8"))["command"], "test")
            self.assertIn("ELSM automation report", text_path.read_text(encoding="utf-8"))
            self.assertIn("ELSM-AUTOMATION", log_file.read_text(encoding="utf-8"))
            if sys.platform != "win32":
                self.assertEqual(text_path.stat().st_mode & 0o777, 0o600)
                self.assertEqual(json_path.stat().st_mode & 0o777, 0o600)
                self.assertEqual(log_file.stat().st_mode & 0o777, 0o600)

    def test_output_path_guard_rejects_system_directories_and_unmarked_logs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaises(ValueError):
                CLI.validate_output_paths(Path("/etc"), root / "logs" / "automation.log")
            with self.assertRaises(ValueError):
                CLI.validate_output_paths(
                    CLI.ROOT / "reports",
                    CLI.ROOT / "logs" / "automation.log",
                )
            with self.assertRaises(ValueError):
                CLI.validate_output_paths(root / "reports", root / "automation.txt")
            CLI.validate_output_paths(root / "reports", root / "logs" / "automation.log")

    def test_log_writer_refuses_unrelated_existing_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            report_dir = directory / "reports"
            log_file = directory / "logs" / "automation.log"
            log_file.parent.mkdir()
            log_file.write_text("unrelated log data\n", encoding="utf-8")
            report = CLI.report_payload("test", None, [CLI.check_record("ok", "PASS", "")])
            with self.assertRaises(OSError):
                CLI.persist_report(report, report_dir, log_file)

    def test_config_rejects_repository_paths_outside_project(self):
        config = CLI.load_config(CLI.DEFAULT_CONFIG)
        config["repository_files"]["unit_directory"] = "../../outside"
        with self.assertRaises(ValueError):
            CLI.discovered_unit_tests(config)

    def test_discovery_runs_each_unit_test_once_and_failure_is_not_hidden(self):
        config = CLI.load_config(CLI.DEFAULT_CONFIG)
        discovered = CLI.discovered_unit_tests(config)
        self.assertTrue(any(path.name == "test_automation_cli.py" for path in discovered))
        with mock.patch.object(
            CLI,
            "run_command",
            side_effect=lambda name, command, cwd=CLI.ROOT: CLI.check_record(
                name,
                "FAIL" if name.endswith("test-storage-validation.sh") else "PASS",
                "fixture",
                command=command,
                returncode=1 if name.endswith("test-storage-validation.sh") else 0,
            ),
        ) as run:
            results = CLI.run_test_suite(config)
        executed_unit_names = [call.args[0] for call in run.call_args_list if call.args[0].startswith("Unit test:")]
        self.assertEqual(len(executed_unit_names), len(set(executed_unit_names)))
        self.assertEqual(len(executed_unit_names), len(discovered))
        self.assertEqual(CLI.exit_for_results(results), 1)

    def test_deploy_plan_never_runs_component_commands(self):
        config = CLI.load_config(CLI.DEFAULT_CONFIG)
        results = CLI.deployment_plan(config)
        self.assertGreaterEqual(len(results), 9)
        self.assertTrue(all(result["status"] == "REVIEW REQUIRED" for result in results))
        self.assertTrue(all(not result["command"] for result in results))

    def test_plan_command_succeeds_without_invoking_host_commands(self):
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(
            CLI, "run_command", side_effect=AssertionError("plan must not invoke host commands")
        ):
            output = Path(temporary)
            status = CLI.main(
                [
                    "plan",
                    "--report-dir",
                    str(output / "reports"),
                    "--log-file",
                    str(output / "automation.log"),
                ]
            )
            report = json.loads((output / "reports" / "latest.json").read_text(encoding="utf-8"))
        self.assertEqual(status, 0)
        self.assertEqual(report["summary"]["exit_code"], 0)
        self.assertTrue(all(item["status"] == "REVIEW REQUIRED" for item in report["results"]))

    def test_deploy_command_is_blocked_without_invoking_host_commands(self):
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(
            CLI, "run_command", side_effect=AssertionError("deploy must not invoke host commands")
        ), contextlib.redirect_stdout(io.StringIO()):
            output = Path(temporary)
            status = CLI.main(
                [
                    "deploy",
                    "--profile",
                    "lab",
                    "--report-dir",
                    str(output / "reports"),
                    "--log-file",
                    str(output / "logs" / "automation.log"),
                ]
            )
            report = json.loads((output / "reports" / "latest.json").read_text(encoding="utf-8"))
        self.assertEqual(status, 3)
        self.assertTrue(any(item["status"] == "BLOCKED" for item in report["results"]))

    def test_missing_optional_tools_are_not_run_not_passed(self):
        config = CLI.load_config(CLI.DEFAULT_CONFIG)
        static_result = CLI.check_record("static", "PASS", "")
        with mock.patch.object(CLI.shutil, "which", return_value=None):
            optional = CLI.record_optional_tools(static_result)
        self.assertEqual([result["status"] for result in optional], ["NOT RUN", "NOT RUN"])

    def test_target_validation_is_blocked_without_running_target_commands(self):
        config = CLI.load_config(CLI.DEFAULT_CONFIG)
        with mock.patch.object(CLI, "is_rhel9", return_value=(False, "fixture non-RHEL")):
            with mock.patch.object(CLI, "run_command", side_effect=AssertionError("must not run")):
                results = CLI.run_validation(config)
        self.assertEqual(len(results), 2)
        self.assertTrue(all(result["status"] == "BLOCKED" for result in results))

    def test_invalid_cli_usage_returns_usage_status_without_running_commands(self):
        with contextlib.redirect_stderr(io.StringIO()):
            with mock.patch.object(CLI, "parse_args", side_effect=SystemExit(2)):
                self.assertEqual(CLI.main([]), 2)


if __name__ == "__main__":
    unittest.main()
