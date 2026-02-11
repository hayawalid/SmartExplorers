#!/usr/bin/env python3
"""
ONE-COMMAND FIX for Alembic Setup
Run this from the backend directory: python fix_alembic_simple.py
"""
import os
import sys
from pathlib import Path

def create_file(path: Path, content: str):
    """Create a file with given content"""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"   ✅ Created: {path}")

def main():
    print("\n" + "=" * 80)
    print("  SmartExplorers - One-Command Alembic Fix")
    print("=" * 80 + "\n")
    
    # Determine backend directory
    if Path("app").exists() and Path("alembic.ini").exists():
        backend_dir = Path.cwd()
        print(f"✅ Running from backend directory: {backend_dir}\n")
    else:
        print("❌ Error: Please run this script from the backend directory")
        print("   cd C:\\Users\\hala\\Documents\\GitHub\\SmartExplorers\\backend")
        print("   python fix_alembic_simple.py")
        sys.exit(1)
    
    alembic_dir = backend_dir / "alembic"
    versions_dir = alembic_dir / "versions"
    
    # Create directories
    print("📁 Creating directories...")
    alembic_dir.mkdir(exist_ok=True)
    versions_dir.mkdir(exist_ok=True)
    print("   ✅ alembic/")
    print("   ✅ alembic/versions/\n")
    
    # Create env.py
    print("📝 Creating alembic files...\n")
    
    env_content = """from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.database import Base

# Import all models to register with Base
from app.models import itinerary, travel_space, user, conversation

config = context.config

# Override database URL from settings
config.set_main_option('sqlalchemy.url', settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
"""
    
    create_file(alembic_dir / "env.py", env_content)
    
    # Create script.py.mako
    mako_content = '''"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
'''
    
    create_file(alembic_dir / "script.py.mako", mako_content)
    
    # Create README
    create_file(alembic_dir / "README", "Generic single-database configuration.\n")
    
    # Check .env
    print("\n📋 Checking configuration...\n")
    
    env_file = backend_dir / ".env"
    if env_file.exists():
        with open(env_file, 'r') as f:
            env_content = f.read()
        if "DATABASE_URL" in env_content:
            print("   ✅ .env file has DATABASE_URL")
        else:
            print("   ⚠️  Warning: DATABASE_URL not found in .env")
            print("      Add: DATABASE_URL=sqlite:///./smartexplorers.db")
    else:
        print("   ⚠️  Warning: .env file not found")
    
    # Success message
    print("\n" + "=" * 80)
    print("  ✅ Alembic Setup Complete!")
    print("=" * 80)
    
    print("\n🎯 Next Steps:\n")
    print("1. Create initial migration:")
    print("   python -m alembic revision --autogenerate -m \"Initial migration\"\n")
    print("2. Apply migration:")
    print("   python -m alembic upgrade head\n")
    print("3. Or use direct database initialization:")
    print("   python -c \"from app.database import init_db; init_db()\"")
    
    print("\n" + "=" * 80 + "\n")


if __name__ == "__main__":
    main()