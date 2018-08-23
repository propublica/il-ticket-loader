import string
import random

def main():
    salt = ''.join(random.choice(string.ascii_uppercase + string.digits) for x in range(15))
    salt_file = open("processors/salt.txt", "w")
    salt_file.write(salt)
    salt_file.close()
    return salt_file

if __name__ == '__main__':
    main()