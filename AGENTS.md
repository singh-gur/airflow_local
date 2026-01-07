# AGENTS.md - Development Guide for Agentic Coding Assistants

This document provides guidelines and commands for agentic coding assistants working in this Apache Airflow local development repository.

## Build, Lint, and Test Commands

All commands are run via `just` (command runner). Run `just --list` to see all available recipes.

### Setup and Initialization
```bash
just setup                    # Create directories and .env file
just init                     # Initialize database and create admin user
just init-custom <user> <pw>  # Initialize with custom credentials
```

### Starting and Stopping Services
```bash
just up                       # Start all services (detached)
just up-build                 # Start and rebuild images
just down                     # Stop all services
just restart                  # Restart all services
```

### Linting and Quality Checks
```bash
just lint-dags                # Lint DAG files with pylint
just check-dags               # Check DAG syntax (recommended)
just validate-connections     # Validate Airflow connections
```

### Testing
```bash
just test                     # Run pytest tests in tests/ directory
just task-run <dag> <task> [date]  # Test a specific task locally
just db-status                # Check database connectivity
```

### Container Access
```bash
just bash                     # Enter scheduler container
just cli <args>               # Run airflow CLI command
just python                   # Run Python in Airflow container
```

### DAG Management
```bash
just dags-list                # List all DAGs
just dag-trigger <id>         # Trigger a DAG run
just dag-pause <id>           # Pause a DAG
just dag-unpause <id>         # Unpause a DAG
```

### Quick Syntax Check (No Container)
```bash
python -m py_compile dags/*.py   # Check DAG syntax locally
```

## Code Style Guidelines

### Python Conventions
- **Python 3.9+** required (Airflow 3.x requires Python 3.9+)
- Use **type hints** for function parameters and return values
- Follow **PEP 8** style guidelines
- Use **4 spaces** for indentation (no tabs)
- Maximum line length: **120 characters**
- Use **descriptive variable and function names** (snake_case)

### Import Style
```python
# Standard library imports first
from datetime import datetime, timedelta
from typing import Any

# Then Airflow imports (alphabetical by module)
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

# Then third-party imports
import pytest
```

### DAG File Structure
```python
"""
Module docstring describing the DAG's purpose.
"""
# Imports
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

# Default arguments for all tasks (at module level)
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Helper functions (with docstrings)
def my_task_function(**context):
    """Function description with parameters and return value."""
    pass

# DAG definition (using context manager)
with DAG(
    dag_id='my_dag',
    description='Description of what this DAG does',
    schedule_interval='0 * * * *',  # Cron format or timedelta
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['production', 'etl'],
    default_args=default_args,
) as dag:
    # Task definitions
    pass
```

### Task Naming Conventions
- Use **snake_case** for task_ids (e.g., `extract_data`, `transform_data`)
- Use **descriptive names** that indicate the task's purpose
- Avoid generic names like `task1`, `task2`
- Group related tasks with **TaskGroup** using descriptive group_ids

### Error Handling
- Always use **try/except** blocks for external API calls
- Log errors using Airflow's **task_logger**: `self.log.error()`
- Use **AirflowException** for Airflow-specific errors
- Set appropriate **retries** and **retry_delay** in default_args

### Operator Usage
- Use **BashOperator** for shell commands (with `bash_command`)
- Use **PythonOperator** for Python functions (with `python_callable`)
- Use **BranchPythonOperator** for conditional branching
- Use **TaskGroup** to organize related tasks visually in UI
- Use **XCom** for passing data between tasks

### Configuration and Plugins
- Custom configurations go in `config/airflow_local_settings.py`
- Custom plugins go in `plugins/` directory
- Use `requirements.txt` for Python dependencies
- Environment variables set in `.env` file

### Best Practices
1. **Catchup=False** for production DAGs (unless explicitly needed)
2. **Set owner** to a team or individual for accountability
3. **Use tags** for filtering and organization in UI
4. **Document DAGs** with descriptions for all parameters
5. **Test tasks** locally with `just task-run` before deploying
6. **Use template fields** in operators for dynamic values
7. **Set appropriate timeouts** to prevent stuck tasks

### File Locations
- DAG files: `dags/*.py`
- Configuration: `config/`
- Plugins: `plugins/`
- Tests: `tests/` (if present)
- Requirements: `requirements.txt`

### Dependency Management
- Add pip dependencies to `requirements.txt` (uncomment to use)
- Or set `_PIP_ADDITIONAL_REQUIREMENTS` in `.env` for quick testing
- For production, build custom Docker image with dependencies baked in
