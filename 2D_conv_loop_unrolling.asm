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
# This version has the kernel loop unrolled, we will test how cache/branch prediction would eventually benefit of this #
# Please note that since we had unrolled 9 loops, we obtained a really long piece of code, anyhow we just unrolled
#  both the loops that control the iteration on kernel matrix columns and rows by directly specifing which address whould
#  we access to obtain the respective cell of kernel.

	.data
img_new:  .word	0 : 90000 # img result matrix (no padding)
img:	  .word 0 : 102040 # padded matrix, we assume as input a 300*300 pixel image, so the padded version is a 302*302 pixels matrix
kernel:   .word	0:9 # kernel matrix, we will fill it with values from 0 to 8 (anyhow, you can initialize it as you want in the loopFillKernel loop)
size_img: .word	102040 # this matrix is sized (I+1)*(J+1) word
size_ker: .word 9 # number of words that compose the kernel matrix
I:        .word 302 # num of rows in Img (with padding)
J:	  .word 302 # num of cols in Img (with padding)
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

# START THE PROGRAM
	sw   $zero, conv # set the current value of conv to zero 
	addi $t2, $zero, 1 # set the register that controls loop on rows (i.e. I) to zero, so it controls variable i
loopRows:
	addi $t3, $zero, 1 # $t3 will control variable j, number of columns in img, from now on
	loopCols:
		sw   $zero, conv # set the value of the convolution pixel initially to zero
		andi $t4, 0 # $t4 controls the y in the kernel, aka the rows

#0
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, -1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 0 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, $zero # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  move  $t6, $zero # put in $t6 the column offset of kernel
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
#1
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 0 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 1 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 1 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi  $t6, $zero, 4 # put in $t6 the column offset of kernel
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
#2
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 2 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 2 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi  $t6, $zero ,8 # put in $t6 the column offset of kernel
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
#3
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, -1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 0 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, $zero # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi  $t6, $zero, 0 # put in $t6 the column offset of kernel
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
#4
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 0 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 1 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 1 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi $t6, $zero, 4 # put in $t6 the column offset of kernel
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
#5
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 2 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 2 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi $t6, $zero, 8 # put in $t6 the column offset of kernel
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
#6
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, -1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 0 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 0 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi $t6, $zero, 0 # put in $t6 the column offset of kernel
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
#7
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 0 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 1 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 1 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi $t6, $zero, 4 # put in $t6 the column offset of kernel
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
#8
# SET THE T REGISTERS BACK TO ZERO
and $t0, 0
and $t1, 0
and $t5, 0
and $t6, 0
and $t7, 0
				  # we calculate the convolution between the kernel and the img submatrix
				  # 
				  # pre-calculate J*4 and (x+i-1)*4: that's  because the linear address is l_addr = J*4(y+i-1) + 4*(x+j-1)
				  # first part: (y+i-1) -> $t6
				  addi $t6, $zero, 1 # (y-1)
				  add  $t6, $t6, $t2 # (y+i-1)
				  # second part: J -> $t7
				  la   $t7, J # calculate the offset of the new line of the matrix Img
				  lw   $t7, ($t7) # ..
				  # let's finish the calculation of the address in img
				  addi $t0, $t3, -1  # calculate j-1
				  addi  $t0, $t0, 2 # add it to x
				  mul  $t7, $t7, $t6 # J*(y+i-1) -> $t7
				  add  $t7, $t7, $t0 # add to the previous 4*(x+j-1) -> $t7, so we have the linear address if img in $t7
				  mul  $t7, $t7, 4 # multiply all the stuff by 4
				  
				  # REGISTERS IN USE: {$2, $3, $4, $5, $7}
				  # REGISTERS AVAILABLE : {$0, $1, $6}				 
				  # now we can compute convolution between kernel and matrix img
				  la   $t0, img # put in $t0 the address of img (calculated as address(img)+offset in $t7)
				  add  $t0, $t0, $t7 # ..
				  lw   $t0, ($t0) # put in $t0 the value of img at the specific offset
				  la   $t1, Y # put in register the size of the kernel rows
				  lw   $t1, ($t1) # ..
				  mul  $t1, $t1, 2 # multiply to it the current row number in kernel
				  mul  $t1, $t1, 4 # put in $t1 kernel address				  
				  addi $t6, $zero, 8 # put in $t6 the column offset of kernel
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
			la   $t7, img_new($t6) # calculate img_address + dispatchment
			la   $t6, conv # load address of the convolution calculated so far
			lw   $t6, ($t6) # load the value of conv
			sw   $t6, ($t7) # store the value of conv into the img address				  
				  
	# increment loop counters on matrix img				  
	addi $t3, $t3, 1 # increment loop counter on cols of Img matrix
	la   $t0, J # put in $t0 the address of J
	lw   $t0, ($t0)  # put in $t0 the number of cols
	addi $t0, $t0, -2
	ble  $t3, $t0, loopCols # exit if we processed all the cols
	
addi $t2, $t2, 1 # increment loop counter on rows of Img matrix
la   $t0, I # put in $t0 the address of I
lw   $t0, ($t0)  # put in $t0 the number of rows
addi $t0, $t0, -2
ble  $t2, $t0, loopRows # exit if we processed all the rows (i.e. whole the matrix Img)
