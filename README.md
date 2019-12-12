# Threefold-Circles-Flist

- note server only work with https due to threebot login require this 

- it is recommend to use all variables below and use the domain naming instead ip in HOST_IP

```./container.py create -n 10.102.251.225 -iyocl 9Xk-Wsnhk84DqDv7E52ZZj0Pi8c9 --clientsecret GjrFZzD2MOlbrnlPD0eXvdUPC7PT \ 
-f https://hub.grid.tf/tf-autobuilder/threefoldtech-Threefold-Circles-Flist-autostart-master.flist \ 
--sshkey 'ssh-rsa  AAAAB3NzaC1yc2EAAAADAQABAAABAQC8o0jEGYqe2k7J0TNL6Gg8h86ic3ReiC6THlBnOKPDiKProj/4uMTmi1Qf5OcLIdeHgcP+zy+ZL4kpP7N6VTALRPiTn6Lty6ZP+5mQocaJYosoGLzB6+lx1NW/zXtscv4V3goULiDEx9SBzSuD8wS0k00iHcRjmuFUIfERyYR8mjmWC/sRf1Y7qk9kQjFOLW5Sw0+RLrxr4l2ur/n8bDVgGVpzWypKIsqRU6Rf1HdXWmdAMCucPAkxR5WNies5QFOkyllxI6Fq+G9M0Uf+EubpfpC1oOMWjNFy781M4KZF+FXODcBlwevfvk0HH/5mTHOymIfwVV8vjRzycxjuQib3 pishoy@Bishoy-laptop' \ 
-p '2222:22' -p '80:80' --name tiaga_test -envs SECRET_KEY=22223rsfsfsdfs -envs EMAIL_HOST=test@test.com \ 
-envs EMAIL_HOST_USER=host@mail.com -envs EMAIL_HOST_PASSWORD=emailhostpass -envs HOST_IP=test.circles.com HTTP_PORT=80```

- create your ur https redirection in caddy server 

```


```