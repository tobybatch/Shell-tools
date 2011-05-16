// The Code is Borland's, I just modified it
// to make it Standard C++

//#include <direct.h> // for getcwd
#include <stdlib.h>// for MAX_PATH
//#include <iostream> // for cout and cin

#include <stdio.h>

// function to return the current working directory
// this is generally the application path
int main( int argc, char *argv[] )
{
	if ( argv[1] != NULL )
	{
		int i = chdir (argv[1]);
	}
	// _MAX_PATH is the maximum length allowed for a path
	char currentPath[1024];
	// use the function to get the path
	getcwd(currentPath,1024);
	printf ( "%s\n", currentPath );
	return 0;
}
