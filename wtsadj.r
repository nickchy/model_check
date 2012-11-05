wtsadj <- function(xtsobj)
{
	wtsadj <-mat.or.vec(dim(xtsobj)[1],dim(xtsobj)[2])
	for (i in 1: dim(xtsobj)[1])
	{
		for (j in 1: dim(xtsobj)[2])
		{
			if (xtsobj[i,j] <= -1.5)
			{
				wtsadj[i,j] = -0.1
			}
			else if(xtsobj[i,j] <= -1) 
			{
				wtsadj[i,j] = -0.075
			}
			else if(xtsobj[i,j] <= -0.5) 
			{
				wtsadj[i,j] = -0.05
			}
			else if(xtsobj[i,j] <= 0.5) 
			{
				wtsadj[i,j] = 0
			}
			else if(xtsobj[i,j] <= 1) 
			{
				wtsadj[i,j] = 0.05
			}			
			else if(xtsobj[i,j] <= 1.5) 
			{
				wtsadj[i,j] = 0.075
			}
			else
			{
				wtsadj[i,j] = 0.1
			}
		}
	}
	wtsadj
}