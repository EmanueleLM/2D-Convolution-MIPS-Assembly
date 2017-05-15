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
	or $t2, 1 # set the register that controls loop on rows (i.e. I) to zero, so it controls variable i
loopRows:
	or $t3, 1 # $t3 will control variable j, number of columns in img, from now on
	loopCols:
		andi $t4, 0
		loopKRows:
			sw   $zero, conv # set the value of the convolution pixel initially to zero
			andi $t5, 0 # set register to 0 (please consider to move these two lines between the instructions that handles with $t7, in order to fasten the code)
			
			# pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+j-1) + 4*(x+i-1)
			# first part: J*4 -> $t7
			la   $t7, J # calculate the offset of the new line of the matrix Img
			lw   $t7, 0($t7) # ..
			# second part: 4*(x+i-1) -> $t6
			addi $6, $t4, -1
			add  $t6, $t6, $t2 
			
			# REGISTERS IN USE: {$2, $3, $4, $5, $6, $7}
			# REGISTERS AVAILABLE : {$0, $1}
			loopKCols:
				  
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # let's finish the calculation of the address in img
				  subi $t0, $t3, 1 # calculate j-1
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
				  addi $t4, $t4, 1 # increment the loop counter for the rows of kernel
				  la   $t0, X # put in $t0 the address of X
				  lw   $t0, ($t0) # put in $t0 the number of rows of kernel
				  blt  $t4, $t0, loopKRows # jump to the loop if we have pixel of kernel not processed yet
				  
				  
				  # now we put the new value of convolution in the respective pixel of img_new 
				  # the img_new address is calculated in this way: 
			  	  # ... #
			  	  # ... #
				  
				  # increment loop counters on matrix img				  
				  addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
				  la   $t0, J # put in $t0 the address of J
				  lw   $t0, ($t0)  # put in $t0 the number of cols
				  blt  $t3, $t0, loopCols # exit if we processed all the cols
				  
				  addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
				  la   $t0, I # put in $t0 the address of I
				  lw   $t0, ($t0)  # put in $t0 the number of rows
				  blt  $t2, $t0, loopRows # exit if we processed all the rows (i.e. whole the matrix Img) 
