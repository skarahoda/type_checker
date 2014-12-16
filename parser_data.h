#ifndef _PARSER_DATA_H_
#define _PARSER_DATA_H_

#include <stdlib.h>

#define STR_SIZE 128

#define INT 0
#define REAL 1
#define BOOLEAN 2
#define ARRAY(x) (x + 3)
#define STATIC(x) (x + 6) //expresions that can be evalutated statically

typedef struct {
	char*		id;
	int		type;
	int		size;
} var_node_t;

typedef struct {
	var_node_t*	var_list;
	unsigned int	size;
	unsigned int	counter;
} parser_info_t;

typedef struct {
	float val;
	int type;
	int line;
}token_int_t;

typedef struct {
	char * id;
	int line;
}token_str_t;

void add_to_list(char * id, int t, int s, parser_info_t * my_info);
int get_type(char * id, parser_info_t * my_info);
int get_size(char * id, parser_info_t * my_info);
void print_list(parser_info_t * my_info);
#endif
