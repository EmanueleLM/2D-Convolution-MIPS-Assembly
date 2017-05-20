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
offset:   .word 0 # initial offset of the center of the kernel wrt the matrix img; offset = (#cols_img+1)*4+(j+1)*4 = 4*(#cols_img+j+2)
conv:     .word 0 # variable for the value of the pixel in the new matrix img_new
	.text
	
# SET ALL THE T REGISTERS TO ZERO
and $t0, 0
and $t1, 0
and $t2, 0
and $t3, 0
and $t4, 0
and $t5, 0
and $t6, 0
and $t7, 0

# initialize the kernel matrix (from 1 to 9, e.g. kernel[1,1] will contain value 5, kernel[0,0] the value 1 and so on till 9)
la $t2, kernel
la $t3, size_ker
lw $t3, ($t3)
ori $t4, 1
loopFillKernel:		
	  	sw $t4, ($t2)
	  	mul $t5, $t4, 4
	  	add $t2, $t2, $t5
	  	addi $t4, $t4, 1
	  	ble  $t4, $t3, loopFillKernel
	  	
# SET ALL THE T REGISTERS TO ZERO
and $t0, 0
and $t1, 0
and $t2, 0
and $t3, 0
and $t4, 0
and $t5, 0
and $t6, 0
and $t7, 0

# initialize the img matrix to 1 in each block, 0 in the padding ones
# TODO #
# .. #    
la   $t0, J # put in $t0 the number of elements in a row of img
lw   $t0, ($t0) # ..
mul  $t0, $t0, 4 # we calculate in place the size of a row of words
addi $t7, $zero, 1 # set the value of each img pixel to 1
addi $t2, $zero, 1 # set the register that controls loop on rows (i.e. I) to zero, so it controls variable i
loopFillRowsImg:
		addi $t3, $zero, 1 # $t3 will control variable j, number of columns in img, from now on
		loopFillColsImg:
				mul $t4, $t2, $t0
				mul $t5, $t3, 4
				add $t6, $t4, $t5 # in $t6 we have the displacement of the img pixel we want to set to 1
				sw  $t7, img($t6) # set the pixel to 1
				
		 		# increment loop counters on matrix img				  
				addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
				la   $t0, J # put in $t0 the address of J
				lw   $t0, ($t0)  # put in $t0 the number of cols
				blt  $t3, $t0, loopFillColsImg # exit if we processed all the cols
				  
				addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
				la   $t0, I # put in $t0 the address of I
				lw   $t0, ($t0)  # put in $t0 the number of rows
				blt  $t2, $t0, loopFillRowsImg # exit if we processed all the rows (i.e. whole the matrix Img) 

	  	
# SET ALL THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t2, 0
and $t3, 0
and $t4, 0
and $t5, 0
and $t6, 0
and $t7, 0	  

# START THE PROGRAM
	  
	addi $t2, $zero, 1 # set the register that controls loop on rows (i.e. I) to zero, so it controls variable i
loopRows:
	addi $t3, $zero, 1 # $t3 will control variable j, number of columns in img, from now on
	loopCols:
		sw   $zero, conv # set the current value of conv to zero
		andi $t4, 0
		loopKRows:
			sw   $zero, conv # set the value of the convolution pixel initially to zero
			andi $t5, 0 # set register to 0 (please consider to move these two lines between the instructions that handles with $t7, in order to fasten the code)
					
			# REGISTERS IN USE: {$2, $3, $4, $5, $6, $7}
			# REGISTERS AVAILABLE : {$0, $1}
			loopKCols:				  
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+j-1) + 4*(x+i-1)
				  # first part: 4*(x+i-1) -> $t6
				  addi $6, $t4, -1
				  add  $t6, $t6, $t2 
				  # second part: J*4 -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, 0($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  add  $t0, $t0, $t5 # add it to y
				  mul  $t7, $t7, $t0 # J*4(y+j-1) -> $t7
				  add  $t7, $t7, $t6 # add to the previous 4*(x+i-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  mul  $t1, $t4, 4 # put in $t1 kernel_num_of_rows*4
				  mul  $t6, $t5, 4 # put in $t6 the column offset of kernel
				  la   $t1, kernel($t1)
				  add  $t1, $t1, $t6 # we finally have in $t1 the address of kernel specific pixel
				  lw   $t1, ($t1) # we put in the register the value of the variable at that memory address
				  
				  # REGISTERS IN USE: {$t0, $t1, $2, $3, $4, $5}
				  # REGISTERS AVAILABLE : {$t6, $t7}				  
				  # calculate kernel*img
				  mul  $t1, $t1, $t0  # multiply kernel*img
				  la   $t6, conv # put in $t6 the content of conv
				  lw   $t6, ($t6) # ..
				  add  $t1, $t1, $t6 # conv += kernel*img
				  sw   $t1, conv
				  
				  # .. #
				  # .. #
				  
				  # we increment the loop's variable and we exit form each respective loops if the have reached their assignation boundary
				  #
				  addi $t5, $t5, 1 # increment the loop counter for the rows of kernel
				  la   $t0, Y # put in $t0 the address of X
				  lw   $t0, ($t0) # put in $t0 the number of rows of kernel
				  blt  $t5, $t0, loopKCols # jump to the loop if we have pixel of kernel not processed yet

				  addi $t4, $t4, 1 # increment the loop counter for the rows of kernel
				  la   $t0, X # put in $t0 the address of X
				  lw   $t0, ($t0) # put in $t0 the number of rows of kernel
				  blt  $t4, $t0, loopKRows # jump to the loop if we have pixel of kernel not processed yet
				  
				  
				  # now we put the new value of convolution in the respective pixel of img_new 
				  # the img_new address is calculated in this way: img_address = 4(i*J)+4*j = 4(i*J+j)
				  la   $t6, J
				  lw   $t6, ($t6)
				  mul  $t6, $t6, $t2 # i*J
				  add  $t6, $t6, $t3 # i*J+j
				  mul  $t6, $t6, 4 # 4(i*J+j), the dispatchment of img new pixel
				  la   $t7, img_new($t6) # calculate img_address + dispatchment
				  la   $t6, conv # load address of the convolution calculated so far
				  lw   $t6, ($t6) # load the value of conv
				  sw   $t6, ($t7) # store the value of conv into the img address				  
				  
				  # increment loop counters on matrix img				  
				  addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
				  la   $t0, J # put in $t0 the address of J
				  lw   $t0, ($t0)  # put in $t0 the number of cols
				  blt  $t3, $t0, loopCols # exit if we processed all the cols
				  
				  addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
				  la   $t0, I # put in $t0 the address of I
				  lw   $t0, ($t0)  # put in $t0 the number of rows
				  blt  $t2, $t0, loopRows # exit if we processed all the rows (i.e. whole the matrix Img) 
