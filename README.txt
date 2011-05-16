These scripts rely on each other so yo9u should place them all in your path.

As root:

cd /usr/local && svn co https://office.neontribe.co.uk/svn/neontribe/shelltools/trunk bin && chmod 755 /usr/local/bin/*

I note that you will need to compile the where_am_i binary:
   gcc -o /usr/local/bin/where_am_i /usr/local/bin/where_am_i.c 

Then make sure /usr/local/bin is in your path
