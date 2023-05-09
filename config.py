import sqlalchemy
import os
from cryptography.fernet import Fernet

WALLET_DIR = "./wallet"
ENCRYPTED_DIR = "./encrypted"


def decrypt_file(file_path: str, output_location: str) -> None:
    """Decrypts given file using key stored in WIEJSKA_ONLINE_ENCRYPTION_KEY env var.
    Args:
        file_path (str): encrypted file path
        output_location (str): path where decrypted file should be placed
    """
    fernet = Fernet(os.environ["WIEJSKA_ONLINE_WALLET_ENCRYPTION_KEY"])
    with open(file_path, "rb") as enc_file:
        encrypted = enc_file.read()
    decrypted = fernet.decrypt(encrypted)
    with open(output_location, "wb") as dec_file:
        dec_file.write(decrypted)


def db_session():
    """Creates session with oracle cloud database using local wallet file and user credentials
    from WIEJSKA_ONLINE_USER_NAME and WIEJSKA_ONLINE_PASSWORD env vars.

    Returns:
        sqlalchemy.orm.Session: object that represent session with database and allow you to modify its content.
    """
    if not os.path.exists(WALLET_DIR):
        os.mkdir(WALLET_DIR)
        decrypt_file(ENCRYPTED_DIR + "/ewallet.pem", WALLET_DIR + "/ewallet.pem")
        decrypt_file(ENCRYPTED_DIR + "/tnsnames.ora", WALLET_DIR + "/tnsnames.ora")

    engine = sqlalchemy.create_engine(
        f"oracle+oracledb://:@",
        connect_args={
            "user": os.environ["WIEJSKA_ONLINE_USER_NAME"],
            "password": os.environ["WIEJSKA_ONLINE_PASSWORD"],
            "dsn": os.environ["WIEJSKA_ONLINE_CS"],
            "config_dir": "./wallet",
            "wallet_location": "./wallet",
            "wallet_password": os.environ["WIEJSKA_ONLINE_WALLET_PASSWORD"],
        },
        poolclass=sqlalchemy.pool.NullPool,
    )

    return engine




