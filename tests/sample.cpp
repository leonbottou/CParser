// Sample C++ code to test lcdecl

// Simple class
class Point {
private:
    int x, y;
public:
    Point(int x, int y);
    ~Point();
    void setX(int newX);
    int getX();
};

// Class with inheritance
class Shape {
public:
    virtual void draw() = 0;
    virtual ~Shape();
};

class Circle : public Shape {
private:
    double radius;
public:
    Circle(double r);
    void draw();
    void draw(int color);
};

// Multiple inheritance
class Printable {
public:
    virtual void print();
};

class Serializable {
public:
    virtual void serialize();
};

struct Document : public Printable, private Serializable {
public:
    Document();
    void print();
};

// References
void processPoint(Point& p);
Point& getGlobalPoint();

// Inline member functions
class Inline {
public:
    int x;
    Inline() { x = 0; }
    void setX(int val) { x = val; }
    int getX() { return x; }
};
