# Peer to Peer Messenger
This project allows to send text messages between two devices. The messages are transferred in Peer to Peer
so it can works only if the two devices are on the same local network. You can just share data from you smartphone
and have the other device connect to it (You don't even need to have internet for this to work).

I used Flutter for cross-platform compatibility (well, I could have used Java like I always do but
I wanted to change for once).

## Why this project
Sometimes I want to transfer some text (e.g. a WiFi password, or a long text from my smartphone I wantù
to copy in a document in my laptop) from my smartphone to my computer, or vice/versa,
but everytime I wanted to do that, I'd have to send the text to myself on Fb or by mail and then open a web browser
in my computer (it is worth mentioning it as my computer is really slow) and then log into my acccount, etc...

## Android app
The Android app allows you to start conversations, and store sent/received messages.

![android app screenshots](https://raw.githubusercontent.com/tambapps/p2p-chat/main/images/android.jpg)

## Command-line app (desktop)
The command line app allows you to send/receive messages

![command line app screenshots](https://raw.githubusercontent.com/tambapps/p2p-chat/main/images/commandline.png)


## Core
This is the library to perform chats. This is where (most of) the magic happens

## How it works
There is two kind of peers: the client and the server.
Each peer starts a server and multicast its server's entry point (address + port) across a multicast group.
The peers use a logic so that only one peer connects to the server of the other (it would be useless to have two connections
for one chat).

Then, the chat can begin