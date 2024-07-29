def check(input):
    if not input:
        return False

    result = int(input.group(4))
    if result < 0 or result > 65535:
        return True

    return False
