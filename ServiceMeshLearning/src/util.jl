
function softclamp(x, xmin, xmax)
    x = xmax - softplus(xmax - x)
    x = xmin + softplus(x - xmin)
    return x
end