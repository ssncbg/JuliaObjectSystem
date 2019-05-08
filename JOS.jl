#PERGUNTAR:
# 1. C1 = make_class(:C1, [], [:a]) -> o que retorna, o que faz
# 2. c3i2 = make_instance(C3, :b=>2) -> faltam argumentos, o que fazer

function make_class(className, inheritanceList, slotsList)
    template = string("struct ", className)
    for value in slotsList
        template = string(template, "\n$value")
    end
    template =  string(template, "\nend")
    expr = Meta.parse(template)
    eval(expr)
end

macro defclass(className, inheritanceList, slotsList...)
    return :(make_class($className, $inheritanceList, $slotsList))
end

function make_instance(className, slotsList...)
    dict = Dict(slotsList)
    template = string(className, "(")
    for value in fieldnames(className)
        template = string(template, dict[value], ",")
    end
    template = string(template, ")")
    expr = Meta.parse(template)
    eval(expr)
end

make_class(:C1, [], [:a])
make_class(:C2, [], [:b, :c])
make_class(:C3, [C1, C2], [:d])

c1i1 = make_instance(C1, :a=>1)
# c3i1 = make_instance(C3, :a=>1, :b=>2, :c=>3, :d=>4)
c2i1 = make_instance(C2, :b=>2, :c=>3)
