# Databricks notebook source
import socket
stor = socket.gethostbyname_ex("blkstor.dfs.core.windows.net")
print ("\n\nThe IP Address of the Domain Name is: "+repr(stor))
kv = socket.gethostbyname_ex("blk-kv.vault.azure.net")
print ("\n\nThe IP Address of the Domain Name is: "+repr(kv))
