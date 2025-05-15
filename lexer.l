%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%%

"पूर्णांक"           { return TK_INT; }
"दशमलव"             { return TK_FLOAT; }
"स्ट्रिंग"           { return TK_STRING_TYPE; }
"छापो"              { return TK_PRINT; }
"जब तक"            { return TK_WHILE; }
"करो"               { return TK_DO; }

\"([^\\\"]|\\.)*\" {
    yylval.str = strdup(yytext);
    yylval.str[strlen(yylval.str) - 1] = '\0';
    memmove(yylval.str, yylval.str + 1, strlen(yylval.str));
    return STRING;
}

[0-9]+\.[0-9]+      { yylval.num = atof(yytext); return NUMBER; }
[0-9]+              { yylval.num = atoi(yytext); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

";"                 { return SEMICOLON; }
"="                 { return ASSIGN; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MUL; }
"/"                 { return DIV; }

[ \t\r\n]+          ; // Skip whitespace
.                   { printf("Unknown character: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}