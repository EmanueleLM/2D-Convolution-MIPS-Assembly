# 2--D convolution in MIPS--assebly #
# @author: Emanuele La Malfa    12/05/2017   #
#
# We take as input two matrices, Img, whose shape is I rows and J columns, which usually represents an image of I*J pixels, 
# and a kernel matrix K, whose shape is X rows and Y cols. please note that we assume X << I and Y << J 
# We then apply convolution by calculating the sum of the products between each submatrix in Img and the kernel K 
# and we store the result in a new matrix Img': 
#	we assume to work with a black and white image i.e. just a layer (no tridiemnsional layers are considered such as RGB images)
#	we assume that the dimension of the kernel is 3*3
#	we assume that the 'center' of the kernel is K(1,1) (I and J both belongs to teh range [0,2])
#	we assume to padd the Img matrix with a border pixel on each dimension (i.e. we will obtain a J+1,I+1 matrix)
#	we assume that teh padding is done by assuming 0 (zero) as value fo te respective pixel
#
# This preliminary version is not optimized at all: we will study an optimized verision of the algorithm in the future #

	.data
img:	  .word 0 : 90601 # padded matrix, we assume as input a 300*300 pixel image, so the padded version is a 301*301 pixels matrix
img_new:  .word	0 : 90000 # img result matrix (no padding)
kernel:   .word	0:9
size_img: .word	90601
size_ker: .word 9
I:        .word 300 # num of rows in Img
J:	  .word 300 # num of cols in Img
X: 	  .word 3 # num of rows in kernel
Y:        .word 3 # num of cols in kernel
	.text
	la $t0, img
	la $t1, J # load address of J in register
	lw $t1, 4($t1) # load value of the displacement of first element non-padding of Img in register
	add  $t1, $t0, $t1 # add the offset of the matrix, now $t1 points to the first element of Img non-padding
	move $t2, $zero # set the register that controls loop on rows (i.e. I) to zero
loopRows:
	move $t3, $zero
	loopCols:
		move $t4, $zero
		loopKRows:
			move $t5, $zero
			loopKCols:				  
				  addi $t5, $t5, 1 # increment the loop counter for the rows of kernel
				  la   $t0, Y # put in $t0 the address of Y
				  lw   $t0, -4($t0) # put in $t0 the number of cols of kernel
				  bne  $t5, $t0, loopKCols # jump to the loop if we have pixel of kernel not processed yet

				  addi $t4, $t4, 1 # increment the loop counter for the rows of kernel
				  la   $t0, X # put in $t0 the address of X
				  lw   $t0, -4($t0) # put in $t0 the number of rows of kernel
				  bne  $t4, $t0, loopKRows # jump to the loop if we have pixel of kernel not processed yet
		  
				  addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
				  la   $t0, J # put in $t0 the address of J
				  lw   $t0, 0($t0)  # put in $t0 the number of cols
				  bne  $t3, $t0, loopCols # exit if we processed all the cols
				  
				  addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
				  la   $t0, I # put in $t0 the address of I
				  lw   $t0, 0($t0)  # put in $t0 the number of rows
				  bne  $t2, $t0, loopRows # exit if we processed all the rows (i.e. whole the matrix Img) 