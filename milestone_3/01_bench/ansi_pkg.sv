package ansi_pkg;

    // Reset
    localparam string COLOR_RESET   = "\033[0m";

    // Regular Colors
    localparam string COLOR_BLACK   = "\033[0;30m";
    localparam string COLOR_RED     = "\033[0;31m";
    localparam string COLOR_GREEN   = "\033[0;32m";
    localparam string COLOR_YELLOW  = "\033[0;33m";
    localparam string COLOR_BLUE    = "\033[0;34m";
    localparam string COLOR_MAGENTA = "\033[0;35m";
    localparam string COLOR_CYAN    = "\033[0;36m";
    localparam string COLOR_WHITE   = "\033[0;37m";

    // Bold Colors
    localparam string BOLD_BLACK   = "\033[1;30m";
    localparam string BOLD_RED     = "\033[1;31m";
    localparam string BOLD_GREEN   = "\033[1;32m";
    localparam string BOLD_YELLOW  = "\033[1;33m";
    localparam string BOLD_BLUE    = "\033[1;34m";
    localparam string BOLD_MAGENTA = "\033[1;35m";
    localparam string BOLD_CYAN    = "\033[1;36m";
    localparam string BOLD_WHITE   = "\033[1;37m";

    // Background Colors
    localparam string BG_RED    = "\033[41m";
    localparam string BG_GREEN  = "\033[42m";
    localparam string BG_YELLOW = "\033[43m";
    localparam string BG_BLUE   = "\033[44m";
    localparam string BG_CYAN   = "\033[46m";

endpackage
