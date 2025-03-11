from string import ascii_lowercase as abc
from string import ascii_uppercase as ABC
import random

def pass_gen(nums: int, lower: int, upper: int) -> str:
    password = []
    special_char = ["!", "@", "#", "$", "%", "^", "&", "*"]

    for i in range(nums):
        password.append(str(random.randint(0, 9)))

    for i in range(lower):
        password.append(random.choice(abc))

    for i in range(upper):
        password.append(random.choice(ABC))

    for i in range(len(password) // 2):
        password.append(random.choice(special_char))

    random.shuffle(password)

    return ''.join(password)


if __name__ == "__main__":
    print("Welcome to the basic password generator\n")
    number_of_nums = int(input("Enter number count: "))
    number_of_lower = int(input("Enter lowercase count: "))
    number_of_upper = int(input("Enter uppercase count: "))
    name = input("What is your name?: ")

    print(f"\nHello {name.capitalize()}, Here is your password: {pass_gen(number_of_nums, number_of_lower, number_of_upper)}")