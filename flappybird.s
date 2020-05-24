#####################################################################
#
# CSC258H5S Winter 2020 Assembly Programming Project
# University of Toronto Mississauga
#
# Group members:
# - Student 1: Litao Chen, 1004545842
# - Student 2: Kamran Badirov, 1005506971
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
# - Milestone 1
# - Milestone 2
# - Milestone 3
# - Milestone 4
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Feature 2: More realistic physics, the more times you fly in a row, the more flying strength you will get 
#               if you keep dropping, the droping speed will increase by time.
# 2. Feature 4: Changing the game difficulty, when game goes furthur. The speed of obstacle will increase until it reaches its limit.
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - Here are some register that won' change its value and its meaning
# - $t0 = 0 means game is on, $t0 != 1 means game ends
#####################################################################
.data 
    displayAddress: .word  0x10008000
    yellow: .word 0xfff86b
    white: .word 0xffffff
    black : .word 0x000000
    blue: .word 0x8ac1ff
    red:  .word 0xfc0303
    birdBlock: .word 1688,1696,1816,1820,1824,1828,1944,1952	# set 1x10008000 as 0, it means the index of unit that bird is at
    green: .word 0x1eb319
    obstacle: .space 416
    timer: .space 8
    obstacleEdge: .space 128
    mapEdge: .word 
    newline: .asciiz "\n"
    upspeed: .space 4
    dropspeed: .space 4
    obstacleSpeed: .space 4
    beginingTime: .space 4
    bye: .word 0,128,256,260,264,268,272,280,384,392,400,404,408,512,516,520,536,656,660,664
        lostMessage: .asciiz "Flappy bird died :(`.."

.text
.globl main

main:

ChangeBackground:		# $t0, $t1, $t2, $t3 used
  lw $t0, displayAddress
  lw $t1, blue
  li $t2, 0        		# Initialize beginning  
  li $t3, 1024     		# Initialize end  
  
start_loop_1:  			# $t0, $t1, $t2, $t3, $t4, $t5 used
  beq $t2, $t3, INITDONE
  sll $t4, $t2, 2
  add $t5, $t4, $t0
  sw $t1, 0($t5)	        # paint the  t2th unit red.  
  
  addi $t2, $t2, 1    		# Increment counter  
  b start_loop_1     
				# $t0, $t1, $t2, $t3, $t4, $t5 freed
							

INITDONE:
    li $t0, 0		# $t0 = 0 game continue, $t0 = 1 game ends
    li $v0, 30      	# call getTime(), $a0 = lower 32 bits, $a1 = upper 32 bits
    syscall
    move $t1,$a0		# $t1 = lower 32 bits (in millisecond)
    
    la $t2, beginingTime
    sb $t1, 0($t2)
    li $t4, 100
    la $t5, obstacleSpeed
    sb $t4, 0($t5)
        
    add $t9, $t1, $t4
    addi $sp, $sp, -4
    sw $t9, 0($sp)
    
    li $v0, 42
    li $a1, 25
    syscall
    jal initObstacle
    
    la $a1, birdBlock		# $a1 = &birdBlock or birdBlock[0]
    jal setBird			# initial the position of bird
    
    la $t1, upspeed
    la $t2, dropspeed
    li $t3, 1
    sb $t3, 0($t2)
    li $t3, -1
    sb $t3, 0($t1)
    GAMEINIT:			# A while loop
        li $t0, 0		# $t0 = 0 game continue, $t0 = 1 game ends
        li $v0, 30      	# call getTime(), $a0 = lower 32 bits, $a1 = upper 32 bits
        syscall
        move $t1,$a0		# $t1 = lower 32 bits (in millisecond)
        
        addi $t2, $t1, 250
        la $t3, timer
        sw $t1, 0($t3)
        sw $t2, 4($t3)
    GAMEON:
        checkMove1:
            la $t3, timer
            lw $t1, 0($t3)
            lw $t2, 4($t3)
            lui $t4, 0xffff	# $t4 = first few bit of keyboard address
            lw $t3, 0($t4)	# $t3 = 0xffff0000
            andi $t3, $t3, 0x1  # $t3 = $t3(int)
            beqz $t3, checkMove2 # if $t3 == 0, jump to checkMove2
            lw $t5, 4($t4)	# else $t3 has a value, $t5 = the keyboard input
            la $a1, birdBlock	# $a1 = &birdBlock
            
            
            beq $t5, 102, setMove1	# if $t5 = 102 ( the keyboard input == 'f', jump to Move
            j checkMove2	# else the keyboard input != 'f', jump to checkMove2
            
        checkMove2:
            li $v0, 30		# get time again
            syscall
            la $a1, birdBlock	# $a1 = birdBlock and pass it to the code block
            li $a2, 128		# represent the same colume but next row
            bge $a0, $t2, setMove2	# if current time is larger than futrue game, call  remove
            j checkMove1	# jump to checkMove1
        setMove1:
            la $t6,upspeed
            la $t7,dropspeed
            li $t8, 1
            sb $t8,0($t7)
            lb $t8,0($t6)
            addi $t8,$t8,-1
            sb $t8,0($t6)
            j setMove
        setMove2:
            la $t6,upspeed
            la $t7,dropspeed
            li $t8, -1
            sb $t8,0($t6)
            lb $t8,0($t7)
            addi $t8,$t8,1
            sb $t8,0($t7)
        setMove:
            li $t9, 128
            mult $t9,$t8
            mflo $a2
            jal Move
            jal checkCollision
        j GAMEINIT		# jump to the beginning of the loop
    
    
    
    GAMEOVER:
   	 lw $t0, displayAddress
 	 lw $t1, red
	 li $t2, 0        		
 	 li $t3, 1024    
        
          loop:  			# $t0, $t1, $t2, $t3, $t4, $t5 used
 		 beq $t2, $t3, ByeScene
 		 sll $t4, $t2, 2
 		 add $t5, $t4, $t0
  		 sw $t1, 0($t5)	        # paint the  t2th unit red.  
 		 addi $t2, $t2, 1    		# Increment counter  
  		 b loop     
				# $t0, $t1, $t2, $t3, $t4, $t5 freed		
	

		ByeScene:	
		  li $t1,0	
        	  la $t2, bye
	 	  lw, $t0, displayAddress
		  lw, $t6, yellow
		  BYELOOP:
		      bge $t1, 20, Quit
		      add $t3, $t1,$t1	
     		      add $t3, $t3, $t3
     		      add $t3,$t2,$t3
       		      lw $t4, 0($t3)
       		      add $t4, $t4, $t0
       		      sw  $t6, 0($t4)
		      addi $t1, $t1, 1	# $t1 = $t1 + 1
        	      j BYELOOP			


 Quit:
        li $v0, 10
        syscall

drawBird:
    bne $t0,0,GAMEOVER
    DRAWINIT:
        li $t1, 0		# Index of the loop
        li $t2, 0		# Index of the birdBlock array
        lw $t3, displayAddress	# $t3 = displayAddress
        lw $t4, yellow		# $t4 = yellow
    GETBIRD:
        beq $t1, 8, DRAWDONE	# if $t1 = 8, Done
        addi $t1, $t1, 1	# $t1 = $t1 + 1
        add $t5, $t2, $t2	# $t5 = 2 * $t2 (index)
        add $t5, $t5, $t5	# $t5 = 4 * $t2 
        add $t7, $a1, $t5	# $t7 = &birdBlock + 4 * Index
        lw $t5, 0($t7)		# $t5 = birdBlock[Index]
        add $t6, $t5, $t3	# $t6 = birdBlock[Index] + displayAddress
        sw $t4, 0($t6)		# load yellow on the bit map at $t5
        addi $t2, $t2, 1	# Index = Index + 1
        j GETBIRD
    DRAWDONE:
        lw $t9, 0($sp)
        addi $sp, $sp, 4
        
        li $v0, 30      	# call getTime(), $a0 = lower 32 bits, $a1 = upper 32 bits
        syscall
        move $t1,$a0		# $t1 = lower 32 bits (in millisecond)
        
        bgt $t1,$t9, MOVEOB
        addi $sp, $sp,4
        sw $t9,0($sp)
        j ALLDONE
    MOVEOB:
        li $v0, 42
        li $a1, 25
        syscall
        la $t2,beginingTime
        lb $t3, 0($t2)
        addi $t3, $t4,1000
        la $t4,obstacleSpeed
        lb $t5, 0($t4)
        bge $t1, $t3, ADDSPEED
    KEEPMOVE:
        add $t9, $t1, $t5
        addi $sp, $sp, -4
        sw $t9, 0($sp)
        move $v1, $ra
        jal moveObstacle
        move $ra, $v1
    ALLDONE:
        li $v0,32
        li $a0, 50
        syscall
        jr $ra
    
    ADDSPEED:
        li $t6,30
        beq $t6,$t5,KEEPMOVE
        sb $t1,0($t2)
        addi $t5,$t5,-10
        sb $t5, 0($t4)
        j KEEPMOVE
Move:
    REMOVEINIT:
        li $t1, 0		# Index of the loop
        li $t2, 0		# Index of the birdBlock array
        lw $t3, displayAddress	# $t3 = displayAddress
        lw $t4, blue		# $t4 = black
    REMOVEBIRD:
        beq $t1, 8, REMOVEDONE	# if $t1 = 8, Done
        addi $t1, $t1, 1	# $t1 = $t1 + 1
        add $t5, $t2, $t2	# $t5 = 2 * $t2 (index)
        add $t5, $t5, $t5	# $t5 = 4 * $t2 
        add $t7, $a1, $t5	# $t7 = &birdBlock + 4 * Index
        lw $t5, 0($t7)		# $t5 = birdBlock[Index]
        add $t6, $t5, $t3	# $t6 = birdBlock[Index] + displayAddress
        sw $t4, 0($t6)		# load black on the bit map at $t5
        addi $t2, $t2, 1	# Index = Index + 1
        j REMOVEBIRD
    REMOVEDONE:
        j setBird
        

setBird:
    SETINIT:
        li $t1,0		# $t1 = 0 is the index of the loop
        la $t2, birdBlock	# $t2 = &birdBlock
    SET:
        bge $t1,8, SETDONE	# if $t1 >= 8, loop ends
        add $t3, $t1,$t1	
        add $t3, $t3, $t3	# $t3 = 4 * $t1 , $t1 is loop index and it is also the index of array
        add $t4, $t3, $t2	# $t4 = &birdBlock + index * 4
        lw $t5, 0($t4)		# $t5 = birdBlock[$t1]
        add $t5, $t5, $a2	# $t5 = $t5 + 128, same colume, next row
        sw $t5, 0($t4)		# birdBlock[$t1] = $t5, new address
        addi $t1, $t1, 1	# $t1 = $t1 + 1
        j SET			
    SETDONE:
        j drawBird		# jump to setBird to draw the bird at new position
        
initObstacle:
    OBINIT:
        li $t1, 0		# $t1 = loop index 
        la $a1, obstacle	# $t5 = &obstacle
        addi $t6, $a0, 6	# $t6 = $a0 + 8 (lower bound of obstacle)
        li $t2,0		# $t2 is the index for obstacle list
        la $v0, obstacleEdge
    GETOB:
        bge $t1, 32, drawObstacle	# if $t1 >= 32, jump to INITDONE
        addi $t1, $t1, 1	# $t1 = $t1 + 1
        bge $t1, $a0, CHECKEMPT	# if $t1 >= $a0, jump to CHECKEMPT
    OBCONTINUE:
    	li $t8, 112		# the column index of 28 on map
    	li $t9, 128		# the row index (128 bytes per row)
    	addi $t7, $t1, -1	# we start at row 0, so $t7 = $t1 -1 (row index on the map)
    	mult $t9, $t7		# row index * row
    	mflo $t9		# $t9 = row index * row ($t9 is the first byte of row $t7)
    	add $t8, $t8, $t9	# $t8 is the byte of column 28 at row $t7
    	li $t9, 16		# $t9 = 16
    	mult $t9, $t2		# 16 * row ( This is the byte of every 4 index in obstacle, we input 4 units at the same time)
    	mflo $t9		# $t9 = 16 * row
    	li $t7,0		# $t7 is loop index
    	move $t3,$a0
    	addi $t3,$t3, -1
    	beq $t1, $t3, ADDLOOP
    	move $t3, $a0
    	addi $t3, $t3,6
    	beq $t1, $t3, ADDLOOP
        addi $t4,$t1,-1
        add $t4,$t4,$t4
        add $t4,$t4,$t4
        add $t3, $t4, $v0
        sw $t8, 0($t3)
    ADDLOOP:			# This loop is setting the bytes for each row of map into obstacle 
    	bge $t7, 4, ENDADDLOOP	# if $t7 = 4, jump to ENDADDLOOP
    	add $t3, $t7, $t7	# $t3 = 2 * $t7
    	add $t3, $t3,  $t3	# $t3 = 4 * $t7
    	add $t4, $t3, $t8	# $t4 represent colume 28,29,30,31 on a row ( on map)
    	add $t0, $t9, $t3	# $t0 = index of obstacle, every 4 index + 0,1,2,3
    	add $t0, $t0, $a1	# $t0 is the address on obstacle of index [4*row + $t7]
    	sw $t4, 0($t0)		# load $t4 to obstacle [4*row + $t7]
    	move $t5, $a0
    	addi $t5,$t5, -1
    	beq $t1, $t5,ADDEDGE
    	move $t5, $t6
    	beq $t1, $t5,ADDEDGE
    	addi $t7, $t7, 1	# loop index $7 = $t7 + 1
    	li $t0,0
    	j ADDLOOP
    ENDADDLOOP:
        addi $t2, $t2,1		# obstacle index + 1
        j GETOB
    CHECKEMPT:
        blt $t1, $t6, GETOB	# if $t3 <= $t4 < $t6, jump to GETOB. Means the current row is empty.
        j OBCONTINUE		# if $t4 >= $t6, jumpty to OBCONTINUE
    ADDEDGE:
        beq $t5,$t6, LOWER
        addi $t5, $t1, -1
        j UPPER
        LOWER:
            addi $t5,$t1,-4
        UPPER:
        add $t5,$t5,$t5
        add $t5, $t5,$t5
        add $t3,$t3,$t5
        add $t3,$t3,$v0
        sw $t4,0($t3)
        addi $t7,$t7,1
        j ADDLOOP
drawObstacle:
    
    DOBINIT:
        lw $t9, displayAddress	# $t0 = &displayAddress[0]
    	li $t4, 0		# loop index $t4 = 0
    	la $t5, obstacle	# $t5 = &obstacle
    	lw $t6, green
    DOBLOOP:
        beq $t4, 104, DOBDONE	# if $t4 == len(Obstacle), jump to DOBDONE
        li $t7, 4		# $t7 = 4
        mult $t4, $t7		# index * 4 ( the byte of index $t4)
        mflo $t7		# $t7 = index * 4
        add $t7, $t5, $t7	# $t7 = &Obstacle[$t4]
        lw $t8, 0($t7)		# $t8 = value of Obstacle[$t4]
        
        add $t8, $t8, $t9	# $t8 = a certain index on displayAddress
        sw $t6, 0($t8)		# load green color onto the index of displayAddress
        addi $t4,$t4,1		# index $t4 = $t4 + 1
        j DOBLOOP		
     DOBDONE:
         jr $ra			# return to main code
        
        
moveObstacle:

    MOBINIT:
        li $t1, 0		# Loop index
        la $t2, obstacle
        lw $t9, displayAddress
        lw $t8, blue
        la $t3, obstacleEdge
        li $t4,0
    MOVEDGE:
        beq $t4,32,DONEDGE
        add $t5,$t4,$t4
        add $t5,$t5,$t5
        add $t5,$t5,$t3
        lw $t6,0($t5)
        addi $t6,$t6,-4
        sw $t6,0($t5)
        addi $t4,$t4,1
        j MOVEDGE
        
    DONEDGE:
        lw $t3, 0($t2)
        beq $t3, $zero, REPAINT
        beq $t3, 768, REPAINT
    MOBLOOP:
        beq $t1, 104, drawObstacle
        li $t3, 4
        add $t3, $t1, $t1
        add $t3, $t3, $t3
        add $t3, $t2,$t3
        lw $t4, 0($t3)
        add $t5, $t9, $t4
        sw $t8, 0($t5)
        addi $t4,$t4, -4
        sw $t4, 0($t3)
        addi $t1, $t1, 1
        j MOBLOOP
    REPAINT:
        beq $t1, 104, initObstacle
        li $t3, 4
        add $t3, $t1, $t1
        add $t3, $t3, $t3
        add $t3, $t2,$t3
        lw $t4, 0($t3)
        add $t5, $t9, $t4
        sw $t8, 0($t5)
        addi $t1, $t1, 1
        j REPAINT
         
 checkCollision:
      		  li $t1, 0		# Index of the birdBlock array
      		  li $t2, 0		# INdex of Obstacle array
      		  la $a2, obstacleEdge      # $a2 = obstacle[0]
      		  la $a1, birdBlock
		  CHECKOUTLOOP:
		      beq $t1, 8, checkCollisionDone
		      add $t3,$t1,$t1
		      add $t3,$t3,$t3
		      add $t3,$t3,$a1
		      lw $t3,0($t3)
		      blt $t3,0,GAMEOVER
		      bgt $t3, 4096, GAMEOVER
		      li $t4,0
		      CHECKINLOOP:
		          beq $t4,32,INDONE
		          add $t5,$t4,$t4
		          add $t5,$t5,$t5
		          add $t5,$t5,$a2
		          lw $t5,0($t5)
		          beq $t5,$t3,GAMEOVER
		          addi $t4,$t4,1
		          j CHECKINLOOP
		      INDONE:
		          addi $t1,$t1,1
		          j CHECKOUTLOOP
 		checkCollisionDone:
 			jr $ra
 			

