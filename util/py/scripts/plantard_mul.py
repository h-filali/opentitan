from random import randrange
q = 8380417
R = 1732267787797143553
test = R*q % 2**64
print(test)
a = randrange(q)
b = randrange(q)
res_mod = a*b % q
print("res_mod is: ", str(res_mod))

b = (b*(2**64)) % q
res_plan = (a*b*R) % (2**64)
print("multiplication is: ", hex(res_plan))
# print("AND WITH: ", hex(2**64 - 1))
# res_plan = res_plan & (2**64 - 1)
# print("AND result is: ", hex(res_plan))
res_plan = res_plan >> 32
print("shift down result is: ", hex(res_plan))
res_plan += 1
print("plus 1 result is: ", hex(res_plan))
res_plan *= q
print("times q result is: ", hex(res_plan))
res_plan = res_plan >> 32
print("res_plan is: ", str(res_plan))
# res_plan = (-1 * res_plan*(2**64)) % q
res_plan = (-1 * res_plan) % q
print("res_plan is: ", str(res_plan))

