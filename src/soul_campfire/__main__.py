import os

import dotenv

def main():
    dotenv.load_dotenv()
    print(os.getenv("SERVER_PORT"))

if __name__ == "__main__":
    main()