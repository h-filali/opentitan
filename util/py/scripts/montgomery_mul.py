from random import randrange
q = 8380417
R = 58728449
test = R*q % 2**32
print(test)
a = randrange(q)
b = randrange(q)
res_mod = a*b % q
print("res_mod is: ", str(res_mod))

c = a*b
res_mont = c % (2**32)
res_mont *= R
res_mont = res_mont % (2**32)
res_mont *= q
res_mont += c
res_mont = res_mont % q
print("res_mont is: ", str(res_mont))

