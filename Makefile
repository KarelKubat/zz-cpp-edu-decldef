all: main1 main2

main1: main.cc libtest1.a
	$(CXX) -o $@ -I. $< -L. -ltest1

main2: main.cc libtest2.a
	$(CXX) -o $@ -I. $< -L. -ltest2

libtest1.a: test1.o
	ar rvs $@ test1.o

libtest2.a: test2a.o test2b.o
	ar rvs $@ test2a.o test2b.o

clean:
	rm -f *.o *.a  main1 main2

%.o: %.cc
	$(CXX) -Wall -I. -c -o $@ $<
