struct IntrospectableClass
    name
    inheritance
    slots
end

mutable struct IntrospectableInstance
    className
    slotsValues
end

mutable struct IntrospectableFunction
    name
    parameters
    body
    native_function
end

function make_class(className, inheritance, slots)
    IntrospectableClass(className,
                        inheritance,
                        slots)
end

function make_instance(className, receivingSlotsValues...)
    #TODO: estruturar melhor
    slotsValues = Dict()
    receivingSlotsValues = Dict(receivingSlotsValues)

    for slot in className.slots
        slotsValues[slot] = nothing
    end

    for inheritance in className.inheritance
        for slot in inheritance.slots
            slotsValues[slot] = nothing
        end
    end
    for slot in slotsValues
        if slot.first in keys(receivingSlotsValues)
            slotsValues[slot.first] = receivingSlotsValues[slot.first]
        end
    end

    IntrospectableInstance(className, slotsValues)
end

function get_slot(className, slotName)
    dictSlots = getfield(className, :slotsValues)
    if slotName in keys(dictSlots)
        dictSlots[slotName] === nothing ?
            println("ERROR: Slot $slotName is unbound") : dictSlots[slotName]
    else
        println("ERROR: Slot $slotName is missing")
    end
end


function set_slot!(className, slotName, value)
    dictSlots = getfield(className, :slotsValues)
    if slotName in keys(dictSlots)
        dictSlots[slotName] = value
    else
        println("ERROR: Slot $slotName is missing")
    end
end

function Base.getproperty(instance::IntrospectableInstance, slotName::Symbol)
    get_slot(instance, slotName)
end

function Base.setproperty!(instance::IntrospectableInstance, slotName::Symbol, value)
    set_slot!(instance, slotName, value)
end

macro defclass(className, inheritance, slots...)
    :($className = make_class($className, $inheritance, $slots))
end

@macroexpand @defclass(C5, [], a)

function make_generic(arguments...)

end

function make_method(name, parameters, body)
    native_function = parameters -> body
    println(parameters[1].args[2])
    native_function(parameters[1].args[2])


    #(f::IntrospectableFunction)(x) = f.native_function(x)
end

macro defmethod(expr)
    name = expr.args[1].args[1]
    parameters = tuple(expr.args[1].args[2:end]...)#starting on 2 until the end
    body = expr.args[2].args[2]
    :($(esc(name)) = make_method($(esc(name)), $parameters, $body))
end

@macroexpand @defmethod foo(c::C1) = 1
@defmethod foo(c::C1) = 1
make_method(:foo, :(c::IntrospectableClass,), 1)

C1 = make_class(:C1, [], [:a])
C2 = make_class(:C2, [], [:b, :c])
C3 = make_class(:C3, [C1, C2], [:d])

c1i1 = make_instance(C1, :a=>1)
c2i1 = make_instance(C2, :b=>7, :c=>3)
c2i2 = make_instance(C2, :b=>4, :c=>5)
c3i1 = make_instance(C3, :b=>2)
c3i2 = make_instance(C3, :b=>2, :a=>5)

get_slot(c2i1, :b)
set_slot!(c2i1, :b, 3)
get_slot(c2i1, :b)
get_slot(c3i2, :e)
