"""
    CV in percent: standard deviation relative to mean in %
"""
cv_pct(x) = 100. *Statistics.std(x)/Statistics.mean(x)
