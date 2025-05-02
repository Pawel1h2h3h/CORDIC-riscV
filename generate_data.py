from math import atan2, sqrt, sin, cos, radians, pi

ITERS = 17

scale = 2**16
theta_table = [round(atan2(1, 2**i)*scale) for i in range(ITERS)]


def compute_K(n):
    """
    Compute K(n) for n = ITERS. This could also be
    stored as an explicit constant if ITERS above is fixed.
    """
    k = 1.0
    for i in range(n):
        k *= 1 / sqrt(1 + 2 ** (-2 * i))
    return k

def CORDIC(alpha, n):
    assert n <= ITERS
    K_n = compute_K(n)
    theta = 0.0
    x = 1.0
    y = 0.0
    P2i = 1  # This will be 2**(-i) in the loop below
    for arc_tangent in theta_table[:n]:
        sigma = +1 if theta < alpha else -1
        theta += sigma * arc_tangent
        x, y = x - sigma * y * P2i, sigma * P2i * x + y
        P2i /= 2
    return x * K_n, y * K_n


print(f"to_sincos: {round(compute_K(ITERS)*scale)}")
print(f"scale: {scale}")
print(f"factor: {round(scale*pi/180)}")
print(theta_table)

