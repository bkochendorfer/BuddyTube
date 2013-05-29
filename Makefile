compile:
	./node_modules/coffee-script/bin/coffee -bw -o ./lib -c ./src

setup:
	npm install

server:
	node server.js
