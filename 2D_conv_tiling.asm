# 2--D convolution in MIPS--assebly #
# @author: Emanuele La Malfa    12/05/2017   #
#
# We take as input two matrices, img, whose shape is I rows and J columns, which usually represents an image of I*J pixels, 
# and a kernel matrix K, whose shape is X rows and Y cols. please note that we assume X << I and Y << J 
# We then apply convolution by calculating the sum of the products between each submatrix in Img and the kernel K 
# and we store the result in a new matrix img_new: 
#	we assume to work with a black and white image i.e. just a layer (no tridiemnsional layers are considered such as RGB images)
#	we assume that the dimension of the kernel is 3*3
#	we assume that the 'center' of the kernel is K(1,1) (I and J both belongs to the range [0,2])
#	we assume to apply padding to the img matrix with a border pixel on each dimension (i.e. we will obtain a J+1,I+1 matrix)
#	we assume that the padding is done by assuming 0 (zero) as value fo te respective pixel
#
#    Version with tiling implemented: #
#    This preliminary version is not optimized at all: we will study an optimized verision of the algorithm in the future #
#    e.g. coupling load/store, eliminate redundant accesses in memory etc.

	.data
img_new:  .word	0 : 90000 # img result matrix (no padding)
img:	  .word 0 : 102040 # padded matrix, we assume as input a 300*300 pixel image, so the padded version is a 302*302 pixels matrix
kernel:   .word	0:9 # kernel matrix, we will fill it with values from 0 to 8 (anyhow, you can initialize it as you want in the loopFillKernel loop)
size_img: .word	102040 # this matrix is sized (I+1)*(J+1) words
size_ker: .word 9 # number of words that compose the kernel matrix
I:        .word 302 # num of rows in Img (with padding)
J:	      .word 302 # num of cols in Img (with padding)
i:        .word 0
j:        .word 0
y:        .word 0
x:        .word 0
img_offset: .word 0 # current address of img + diaplcement due to tiling
small_I:  .word 50
small_J:  .word 50
til_vec_addresses: .word 0:36 # create a vector of img addresses where the tiling will start	
til_vec_addresses_size: .word 36 # size of tic_vec_addresses (i.e. number of tilings)
counter:  .word 0 # counts the number of times we execute tiling
X: 	  .word 3 # num of rows in kernel
Y:        .word 3 # num of cols in kernel
offset:   .word 0 # initial offset of the center of the kernel wrt the matrix img; offset = (#cols_img+1)*4+(j+1)*4 = 4*(#cols_img+j+2)
conv:     .word 0 # variable for the value of the pixel in the new matrix img_new
	.text
	
# initialize the kernel matrix (from 0 to 8, e.g. kernel[1,1] will contain value 4, kernel[0,0] the value 0 and so on till kernel[2,2]=8)
la $t2, kernel
la $t3, size_ker
lw $t3, ($t3)
andi $t4, 0
loopFillKernel:	
		mul $t5, $t4, 4	
	  	la $t2, kernel($t5)
	  	sw $t4, ($t2)
	  	addi $t4, $t4, 1
	  	blt  $t4, $t3, loopFillKernel
	  	
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
addi $t7, $zero, 1 # set the value of each img pixel to 1
addi $t2, $zero, 1 # set the register that controls loop on rows (i.e. I) to 1, so it controls variable i
loopFillRowsImg:
		la   $t0, J # put in $t0 the number of elements in a row of img
		lw   $t0, ($t0) # ..
		mul  $t0, $t0, 4 # calculate size of a row of img
		mul $t4, $t2, $t0 # calculate the displacement of the new row
		addi $t3, $zero, 1 # set the register that controls loop on rows (i.e. I) to 1, so it controls variable i
		loopFillColsImg:
				mul $t5, $t3, 4 # calculate the diaplcement of a pixel in a column
				add $t6, $t4, $t5 # in $t6 we have the displacement of the img pixel we want to set to 1
				sw  $t7, img($t6) # set the pixel to 1
				
		 		# increment loop counters on matrix img				  
				addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
				la   $t0, J # put in $t0 the address of J
				lw   $t0, ($t0)  # put in $t0 the number of cols
				addi $t0, $t0, -2
				ble  $t3, $t0, loopFillColsImg # exit if we processed all the cols
				  
				addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
				la   $t0, I # put in $t0 the address of I
				lw   $t0, ($t0)  # put in $t0 the number of rows
				addi $t0, $t0, -2
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

# calculate the starting address of each tiling sub matrix of img
# we put the results in a vector of n entries
la   $t7, small_J
lw   $t7, ($t7)
mul  $t7, $t7, 4
la   $t6, small_I
lw   $t6, ($t6)
mul  $t6, $t6, 4
		     andi $t1, 0 # we use this as index for vector tiling
		     loop_til_y: 
		     	        andi $t2, 0 # we use $t2 for x in img
		     		loop_til_x:
    					   mul $t3, $t2, $t6
    					   la  $t4, J
    					   lw  $t4, ($t4)
    					   addi $t4, $t4, -2
    					   mul $t4, $t1, $t4
    					   mul $t4, $t7, $t4
    					   add $t5, $t3, $t4 # address of next index of til_vector
    					   la  $t3, til_vec_addresses
					   mul $t4, $t0, 4
					   add $t3, $t3, $t4 # address of til_vec + displacement
					   sw   $t5, ($t3)
					   addi $t0, $t0, 1
				addi $t2, $t2, 1
				addi $t3, $zero, 6 # put here a register to control it!
				blt  $t2, $t3, loop_til_x
			addi $t1, $t1, 1
			addi $t3, $zero, 6 # change this one in order to access a non-constant element
			blt  $t1, $t3, loop_til_y   					   
    					   
            
# START THE PROGRAM
loopTiling:
	la   $t0, counter
	lw   $t0, ($t0)
	beq  $t0, 36, end
	mul  $t1, $t0, 4 # current address of vector tiling 
	la   $t2, til_vec_addresses($t1)
	lw   $t1, ($t2)
	sw   $t1, img_offset
	
	addi $t0, $t0, 1
	sw   $t0, counter

	sw   $zero, conv # set the current value of conv to zero 
	la   $t2, i
	lw   $t2, ($t2)
	addi $t2, $zero, 1 # set the register that controls loop on rows (i.e. I) to zero, so it controls variable i
	sw   $t2, i
loopRows:
	la   $t3, j
	lw   $t3, ($t3)
	addi $t3, $zero, 1 # $t3 will control variable j, number of columns in img, from now on
	sw   $t3, j
	loopCols:
		sw   $zero, conv # set the value of the convolution pixel initially to zero
		la   $t4, y
		lw   $t4, ($t4)
		andi $t4, 0 # $t4 controls the y in the kernel, aka the rows
		sw   $t4, y
		loopKRows:
			la   $t5, x
			lw   $t5, ($t5)
			andi $t5, 0 # set register to 0 (please consider to move these two lines between the instructions that handles with $t7, in order to fasten the code)
			sw   $t5, x		
			# REGISTERS IN USE: {$2, $3, $4, $5, $6, $7}
			# REGISTERS AVAILABLE : {$0, $1}
			loopKCols:				  
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $t4, -1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  add  $t0, $t0, $t5 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img_offset # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  lw   $t1, ($t0)
				  la   $t0, img($t1)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, $t4 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  mul  $t6, $t5, 4 # put in $t6 the column offset of kernel
				  add  $t1, $t1, $t6 # add the row offset 
				  la   $t1, kernel($t1) # put in register the kernel+offest of the next pixel
				  lw   $t1, ($t1) # we put in the register the value of the variable at that memory address
				  
				  # REGISTERS IN USE: {$t0, $t1, $2, $3, $4, $5}
				  # REGISTERS AVAILABLE : {$t6, $t7}				  
				  # calculate kernel*img
				  mul  $t1, $t1, $t0  # multiply kernel*img
				  la   $t6, conv # put in $t6 the content of conv
				  lw   $t6, ($t6) # ..
				  add  $t1, $t1, $t6 # conv += kernel*img
				  sw   $t1, conv

				  # we increment the loop's variable and we exit form each respective loops if the have reached their assignation boundary
				  #
				  la   $t5, x
				  lw   $t5, ($t5)
				  addi $t5, $t5, 1 # increment the loop counter for the rows of kernel
				  sw   $t5, x
				  la   $t0, X # put in $t0 the address of X
				  lw   $t0, ($t0) # put in $t0 the number of cols of kernel
				  blt  $t5, $t0, loopKCols # jump to the loop if we have pixel of kernel not processed yet

			la   $t4, y
			lw   $t4, ($t4)
			addi $t4, $t4, 1 # increment the loop counter for the rows of kernel
			sw   $t4, y
			la   $t0, Y # put in $t0 the address of X
			lw   $t0, ($t0) # put in $t0 the number of rows of kernel
			blt  $t4, $t0, loopKRows # jump to the loop if we have pixel of kernel not processed yet
				  
				  
			# now we put the new value of convolution in the respective pixel of img_new 
			# the img_new address is calculated in this way: img_address = 4(i*J)+4*j = 4(i*J+j)
			la   $t6, J
			lw   $t6, ($t6)
			addi $t6, $t6, -2
			addi $t7, $t2, -1
			mul  $t6, $t6, $t7 # (i-1)*J
			addi $t7, $t3, -1
			add  $t6, $t6, $t7 # (i-1)*J+(j-1)
			mul  $t6, $t6, 4 # 4((i-1)*J+(j-1)), the dispatchment of img new pixel
			la   $t7, img_new($t6)
			la   $t5, img_offset
			lw   $t5, ($t5)
			add  $t7, $t7, $t5
			la   $t6, conv # load address of the convolution calculated so far
			lw   $t6, ($t6) # load the value of conv
			sw   $t6, ($t7) # store the value of conv into the img address  
				  
	# increment loop counters on matrix img	
	la   $t3, j
	lw   $t3, ($t3)				  
	addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
	sw   $t3, j
	la   $t0, small_J # put in $t0 the address of J
	lw   $t0, ($t0)  # put in $t0 the number of cols
	ble  $t3, $t0, loopCols # exit if we processed all the cols

la   $t2, i	
lw   $t2, ($t2)		
addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
sw   $t2, i
la   $t0, small_I # put in $t0 the address of I
lw   $t0, ($t0)  # put in $t0 the number of rows
ble  $t2, $t0, loopRows

			 
b loopTiling			 
end:
