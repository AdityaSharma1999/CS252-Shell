
Emma Caraher
willi684@purdue.edu
CS 252
Spring 2015


1. Features specified in the handout that work
	I/O Redirection
	Pipes
	1. Ignoring Ctrl-C
	2. Exit
	3. Printenv
	4. Wildcarding
	5. Zombies
	6. Setenv
	7. Unsetenv
	8. cd [dir]
	9. Supporting special characters, allowing lack of spaces
	10. Allowing quotes (need test 113 and 115)
	11. Allowing escape character
	12. Environment variable expansion
	13. Tilde Expansion
	14. isatty()
	15. Incorporating TTY library
	16. Subshell

2. Extra features implemented
	For extra credit:
		typing [[(redefine ...)]] will replace previous definition or add if not already defined
		typing 
			fiz remove last definition
				will remove last definition added
		typing
			fiz remove ...
				where ... is just name of definition (eg, add)
				will remove first definition with this name


		Does not work:
			two definitions in a row


-------------------------------------------------
User:   
-------------------------------------------------
IO Redirection:          15  of 15 
Pipes:                   15  of 15 
Background and Zombie:   5   of 5
Environment:             10  of 10 
Words and special chars: 2   of 2  
cd:                      5   of 5  
Wildcarding:             14  of 14 
Quotes and escape chars: 5   of 5  
Ctrl-C:                  5   of 5  
Robustness:              10  of 10 
subshell:                10  of 10 
tilde expansion:         4   of 4  
--------------------------------------------------
Total:                   100 of 100














