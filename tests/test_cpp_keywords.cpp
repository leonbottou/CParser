// Test C++ keyword recognition
// This file tests that C++ keywords are properly recognized when -std=c++XX is used

// Test 1: class keyword
class MyClass {
public:
    int x;
private:
    int y;
protected:
    int z;
};

// Test 2: access specifiers in struct (struct defaults to public)
struct MyStruct {
    int a;  // public by default
private:
    int b;  // now private
public:
    int c;  // back to public
};

// Test 3: virtual inheritance
class Base {
public:
    virtual void foo();
};

class Derived : public virtual Base {
public:
    void foo();
};

// Test 4: explicit constructor
class Widget {
public:
    explicit Widget(int size);
};

// Test 5: friend declaration
class A {
    friend class B;
    friend void helper();
private:
    int secret;
};

// Test 6: References (should already work via Pointer{ref=true})
void func(int& ref);
int& getRef();
