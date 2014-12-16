#include "parser_data.h"
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void add_to_list(char * id, int t, int s, parser_info_t * my_info)
{
	int size;
	my_info->size++;
	size = my_info->size;
	my_info->var_list = (var_node_t *) realloc(my_info->var_list, sizeof(var_node_t)*size);
	my_info->var_list[size-1].id = strdup(id);
	my_info->var_list[size-1].type = t + (s == -1 ? 0 : 3 );
	my_info->var_list[size-1].size = s;
}

int get_type(char * id, parser_info_t * my_info)
{
	int i;
	for (i = 0; i < my_info->size; i++)
	{
		if(strcmp(id,my_info->var_list[i].id) == 0)
			return my_info->var_list[i].type;
	}
	return -1;
}

int get_size(char * id, parser_info_t * my_info)
{
	int i;
	for (i = 0; i < my_info->size; i++)
	{
		if(strcmp(id,my_info->var_list[i].id) == 0)
			return my_info->var_list[i].size;
	}
	return -1;
}

void print_list(parser_info_t * my_info)
{
	int i;
	for (i = 0; i < my_info->size; i++)
	{
		printf("id: %s\ntype: %s\nsize: %d\n==========================\n"
			,my_info->var_list[i].id
			,my_info->var_list[i].type%3 == BOOLEAN ? "bool" : 
				my_info->var_list[i].type%3 == INT ? "int" : "real"
			,my_info->var_list[i].size);
	}
}
