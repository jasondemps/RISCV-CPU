#define MAX 10

int main()
{
  volatile int i, add = 0, mult;//, div;

  for (i = 0, add = 0; i < MAX; ++i)
    add += i;

  for (i = 1, mult = 1; i < MAX; ++i)
    mult *= i;

  //for (i = MAX, div = 1)

  return 0;
}
