class CodeSmellType:
    admin_by_default = 'AdminByDefault'
    hardcoded_password = 'HardcodedPassword'
    unrestricted_ip_address = 'UnrestrictedIpAddress'
    invalid_port_ranges = 'InvalidPortRanges'
    empty_password = 'EmptyPassword'


class CodeSmellOutput:
    line_number: int
    line_of_code: str
    type: str
    file_path: str
    suggest_solution: str

    def __init__(self, line_number: int = None,
                 line_of_code: str = None,
                 type: str = None,
                 file_path: str = None,
                 suggest_solution: str = None):
        self.line_number = line_number
        self.line_of_code = line_of_code
        self.type = type
        self.file_path = file_path
        self.suggest_solution = suggest_solution
