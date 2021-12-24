            assume          cs:c,ss:s,ds:d
delay = 3

s           segment         stack
            dw              128 dup(?)
s           ends

d           segment
old1c       dw              0,0
x           dw              ?
d           ends

c           segment
start:      mov             ax, d
            mov             ds, ax

            mov             ax, 351ch           ;get interrupt vector 1c
            int             21h
            push            bx
            push            es                  ;STACK = old 1c interrupt vector
            mov             ax, 251ch           
            lea             dx, tim             ;set new interrupt 1c vector
            push            ds
            push            cs
            pop             ds                  ;25H ds has to be c segment 
            int             21h
            pop             ds                  ;get ds back
            mov             cx, 10
            mov             x,  18*delay
m:          cmp             x,  0
            jnz             m
            mov             x,  18*delay
            mov             ah, 2
            mov             dl, '*'
            int             21h
            loop            m
            pop             ds
            pop             dx
            mov             ax, 251ch
            int             21h
            mov             ax, 4c00h
            int             21h
tim:        push            ax
            push            ds
            mov             ax, d
            mov             ds, ax
            dec             x
            pop             ds
            pop             ax
            iret
c           ends
            end             start