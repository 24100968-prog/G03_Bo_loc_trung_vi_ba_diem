def median3(a,b,c):
    return sorted((a,b,c))[1]

def median_stream(samples):
    out=[]
    hist=[]
    for x in samples:
        hist.append(x)
        if len(hist)<3:
            out.append((False,None))
        else:
            if len(hist)>3:
                hist.pop(0)
            out.append((True,median3(*hist)))
    return out

def mean_stream(samples):
    out=[]
    hist=[]
    for x in samples:
        hist.append(x)
        if len(hist)<3:
            out.append((False,None))
        else:
            if len(hist)>3:
                hist.pop(0)
            out.append((True,sum(hist)//3))
    return out

def test_all_permutations():
    import itertools
    for p in itertools.permutations([1,2,3]):
        assert median3(*p)==2

def test_ties():
    assert median3(2,2,9)==2
    assert median3(2,9,2)==2
    assert median3(9,2,2)==2
    assert median3(5,5,5)==5

def test_impulse():
    assert median_stream([10,11,250])[-1] == (True,11)

def test_mean_difference():
    assert mean_stream([10,11,250])[-1] == (True,90)

def test_boundary():
    assert median3(0,255,128)==128
    assert median3(255,0,128)==128
    assert median3(128,255,0)==128

if __name__=="__main__":
    test_all_permutations()
    test_ties()
    test_impulse()
    test_mean_difference()
    test_boundary()
    print("G03 golden reference PASS")
