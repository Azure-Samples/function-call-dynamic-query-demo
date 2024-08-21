import argparse
import logging

# import struct
import pyodbc
from azure.identity import DefaultAzureCredential

logger = logging.getLogger("sqlapp")


# Function to get a database connection via pyodbc and Azure ID
def get_conn(server, database):
    try:
        credential = DefaultAzureCredential(exclude_interactive_browser_credential=False)
        token_bytes = credential.get_token("https://database.windows.net/.default").token.encode(
            "UTF-16-LE"
        )
        token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
        SQL_COPT_SS_ACCESS_TOKEN = (
            1256  # This connection option is defined by Microsoft in msodbcsql.h
        )

        # Building the connection string using the provided server and database
        connection_string = f"Driver={{ODBC Driver 18 for SQL Server}};Server=tcp:{server},1433;Database={database};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30"

        conn = pyodbc.connect(
            connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct}
        )
        logger.info("Database connection established.")
        return conn
    except Exception as e:
        logger.error(f"Error establishing database connection: {e}")
        raise


def assign_role_for_webapp(conn, app_identity_name):
    try:
        cursor = conn.cursor()

        # Check if the identity exists
        cursor.execute("SELECT name FROM sys.database_principals WHERE name = ?", app_identity_name)
        identity_exists = cursor.fetchone()

        if identity_exists:
            logger.info(f"Found an existing SQL role for identity {app_identity_name}")
        else:
            logger.info(f"Creating a SQL role for identity {app_identity_name}")
            cursor.execute(f"CREATE USER [{app_identity_name}] FROM EXTERNAL PROVIDER")

        logger.info(f"Granting permissions to {app_identity_name}")
        cursor.execute(f"ALTER ROLE db_datareader ADD MEMBER [{app_identity_name}]")
        cursor.execute(f"ALTER ROLE db_datawriter ADD MEMBER [{app_identity_name}]")

        conn.commit()
        cursor.close()
        logger.info("Role assignment completed successfully.")
    except Exception as e:
        logger.error(f"Error assigning roles: {e}")
        raise


def main():
    parser = argparse.ArgumentParser(
        description="Assign roles to managed identity in Azure SQL Database"
    )
    parser.add_argument("--server", type=str, required=True, help="SQL Server hostname")
    parser.add_argument("--database", type=str, required=True, help="SQL Database name")
    parser.add_argument(
        "--app-identity-name", type=str, required=True, help="Azure App Service identity name"
    )

    args = parser.parse_args()

    conn = get_conn(args.server, args.database)

    assign_role_for_webapp(conn, args.app_identity_name)

    conn.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING)
    logger.setLevel(logging.INFO)
    main()
