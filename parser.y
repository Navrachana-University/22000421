%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

int temp_count = 1;

typedef struct {
    char name[100];
    double value;
    char str_value[100];
    int type; // 0 = int, 1 = float, 2 = string
} Variable;

Variable vars[100];
int var_count = 0;

int find_var(const char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(vars[i].name, name) == 0)
            return i;
    }
    return -1;
}

void add_var(const char *name, int type) {
    strcpy(vars[var_count].name, name);
    vars[var_count].value = 0;
    vars[var_count].str_value[0] = '\0';
    vars[var_count].type = type;
    var_count++;
}

void assign(const char *name, double value, int is_float) {
    int idx = find_var(name);
    if (idx == -1) {
        fprintf(stderr, "Error: Variable %s not declared\n", name);
        return;
    }

    if (vars[idx].type == 2) {
        fprintf(stderr, "Error: Cannot assign numeric value to string variable %s\n", name);
        return;
    }

    if (is_float && vars[idx].type == 0) {
        fprintf(stderr, "Warning: Assigning float value to int variable %s, truncating\n", name);
        vars[idx].value = (int)value;
    } else {
        vars[idx].value = value;
    }

    if (vars[idx].type == 1)
        printf("%s = %.2f\n", name, vars[idx].value);
    else
        printf("%s = %d\n", name, (int)vars[idx].value);
}

void assign_str(const char *name, const char *value) {
    int idx = find_var(name);
    if (idx == -1) {
        fprintf(stderr, "Error: Variable %s not declared\n", name);
        return;
    }
    if (vars[idx].type != 2) {
        fprintf(stderr, "Error: Cannot assign string value to non-string variable %s\n", name);
        return;
    }
    strcpy(vars[idx].str_value, value);
    printf("%s = \"%s\"\n", name, vars[idx].str_value);
}

void print_var(const char *name) {
    int idx = find_var(name);
    if (idx == -1) {
        fprintf(stderr, "Error: Variable %s not declared\n", name);
        return;
    }
    if (vars[idx].type == 2)
        printf("PRINT %s = \"%s\"\n", name, vars[idx].str_value);
    else if (vars[idx].type == 1)
        printf("PRINT %s = %.2f\n", name, vars[idx].value);
    else
        printf("PRINT %s = %d\n", name, (int)vars[idx].value);
}
%}

%union {
    char *str;
    double num;
    struct {
        double val;
        int is_float;
    } expr;
}

%token <str> IDENTIFIER STRING
%token <num> NUMBER
%token TK_PRINT TK_INT TK_FLOAT TK_STRING_TYPE
%token ASSIGN SEMICOLON
%token PLUS MINUS MUL DIV
%token TK_WHILE TK_DO


%type <expr> expression

%left PLUS MINUS
%left MUL DIV

%%

program:
    program statement
    | statement
    ;

statement:
    TK_INT IDENTIFIER SEMICOLON {
        add_var($2, 0); free($2);
    }
    | TK_FLOAT IDENTIFIER SEMICOLON {
        add_var($2, 1); free($2);
    }
    | TK_STRING_TYPE IDENTIFIER SEMICOLON {
        add_var($2, 2); free($2);
    }
    | IDENTIFIER ASSIGN expression SEMICOLON {
        assign($1, $3.val, $3.is_float); free($1);
    }
    | IDENTIFIER ASSIGN STRING SEMICOLON {
        assign_str($1, $3); free($1); free($3);
    }
    | TK_PRINT IDENTIFIER SEMICOLON {
        print_var($2); free($2);
    }
    | TK_WHILE expression TK_DO statement {
        while ($2.val != 0) {
            yyparse();
        }
    }
    ;

expression:
    NUMBER {
        $$.val = $1;
        $$.is_float = 0;
    }
    | IDENTIFIER {
        int idx = find_var($1);
        if (idx == -1) {
            yyerror("Variable not declared");
            $$.val = 0;
            $$.is_float = 0;
        } else if (vars[idx].type == 2) {
            yyerror("Cannot use string variable in expression");
            $$.val = 0;
            $$.is_float = 0;
        } else {
            $$.val = vars[idx].value;
            $$.is_float = vars[idx].type == 1;
        }
        free($1);
    }
    | expression PLUS expression {
        $$.val = $1.val + $3.val;
        $$.is_float = $1.is_float || $3.is_float;
        printf("t%d = %.2f + %.2f\n", temp_count++, $1.val, $3.val);
    }
    | expression MINUS expression {
        $$.val = $1.val - $3.val;
        $$.is_float = $1.is_float || $3.is_float;
        printf("t%d = %.2f - %.2f\n", temp_count++, $1.val, $3.val);
    }
    | expression MUL expression {
        $$.val = $1.val * $3.val;
        $$.is_float = $1.is_float || $3.is_float;
        printf("t%d = %.2f * %.2f\n", temp_count++, $1.val, $3.val);
    }
    | expression DIV expression {
        $$.val = $1.val / $3.val;
        $$.is_float = 1;
        printf("t%d = %.2f / %.2f\n", temp_count++, $1.val, $3.val);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error: %s\n", s);
}

int main() {
    printf("Enter your program (end with Ctrl+D):\n");
    return yyparse();
}