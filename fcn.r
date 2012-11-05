rowsd <- function(xtsobj)
{
	rollsd <- rep(0, dim(xtsobj)[1] )

	for (i in 1 : dim(xtsobj)[1])
	{
		rollsd[i] <- sd(as.vector(xtsobj[i, ] ) )
	}
	rollsd
}


