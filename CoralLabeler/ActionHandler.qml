import QtQuick
import QtQuick.Shapes
import Actions

QtObject {
    property list<Actions> doneStack: []
    property list<Actions> undoneStack: []

    //Add curAction to doneStack and clear undoneStack
    //curAction - instantiated Action object
    //ahPerform - Boolean. If true, the ActionHandler performs the action.
    //                     If false, the AH just adds action to stack, assumes it has been done already
    function actionDone(curAction, ahPerform) {
        doneStack.push(curAction)
        if (ahPerform) {
            parseActionDo(curAction)
        }
        while (undoneStack.length > 0) {
            undoneStack.pop() //If another tool has been used, paths have
            //diverged and it does not make sense to redo.
        }
    }
    //Pop from done stack, undo that action, push to undoneStack
    //If there is nothing to undo, do nothing
    function undo() {
        if (doneStack.length>0) {
            var curAction = doneStack.pop()
            parseActionUndo(curAction)
            undoneStack.push(curAction)
        }
    }
    //Pop from undoneStack, do that action, push to done stack
    //if there is nothing to redo, do nothing
    function redo() {
        if (undoneStack.length>0) {
            var curAction = undoneStack.pop()
            parseActionDo(curAction)
            doneStack.push(curAction)
        }
    }
    //Returns true if there are Actions available to undo
    function actToUndo() {
        return doneStack.length>0
    }
    //Returns tru if there are Actions available to redo
    function actToRedo() {
        return undoneStack.length>0
    }

    function parseActionDo(curAction) {
        switch (curAction.typeString) {
            case "CreateAction"://insert into parent data at end
                curAction.shapeParent.data.push(curAction.target);
                break;
            case "DeleteAction":
                //remove elements until I have removed the right element.
                var removedElement = curAction.shapeParent.data.pop();
                var toPutBack = [];
                var idx = 0;
                while (removedElement !== curAction.target) {
                    toPutBack.push(removedElement);
                    removedElement = curAction.shapeParent.data.pop();
                    idx++;
                }
                curAction.idxInParent = idx
                //sucessfully removed, time 2 put the others back
                for (removedElement of toPutBack) {
                    curAction.shapeParent.data.push(removedElement);
                }
                break;
            case "MoveAction":
                var dX = curAction.dX;
                var dY = curAction.dY;
                var sp = curAction.target.data[0]; //Assuming target is a Shape containing a ShapePath
                sp.startX += dX;
                sp.startY +=dY;
                for (var pathEle of sp.pathElements) {
                    pathEle.x+=dX;
                    pathEle.y+=dY;
                }
                break;
            case "ScaleAction":
                //get max/min for x and y to calculate midpoint
                var sp = curAction.target.data[0];
                var max_pt = [sp.startX, sp.startY];
                var min_pt = [sp.startX, sp.startY];
                for (var pathEle of sp.pathElements) {
                    if (pathEle.x > max_pt[0]) {
                        max_pt[0] = pathEle.x
                    }
                    else if (pathEle.x < min_pt[0]) {
                        min_pt[0] = pathEle.x
                    }
                    if (pathEle.y > max_pt[1]) {
                        max_pt[1] = pathEle.y
                    }
                    else if (pathEle.y < min_pt[1]) {
                        min_pt[1] = pathEle.y
                    }
                }
                //calc midpoint, pull out scale factors
                var midpointX = min_pt[0] + (max_pt[0]-min_pt[0])/2
                var midpoint = [min_pt[0] + (max_pt[0]-min_pt[0])/2, min_pt[1]+ (max_pt[1]-min_pt[1])/2]
                var sX = curAction.sX
                var sY = curAction.sY
                //fns to find offset for point
                function dX(x) {
                    return (x-midpoint[0])*(sX-1)
                }
                function dY(y) {
                    return (y-midpoint[1])*(sY-1)
                }
                //apply offset to start and every stored coordinate
                sp.startX +=dX(sp.startX)
                sp.startY +=dY(sp.startY)
                for (var pathEle of sp.pathElements) {
                    pathEle.x += dX(pathEle.x)
                    pathEle.y += dY(pathEle.y)
                }
                break;
            
        }
        
    }

    function parseActionUndo(curAction) {
        switch (curAction.typeString) {
            case "CreateAction"://undo a create = remove
                //can we assume it will always be at the end and not save idx?
                curAction.shapeParent.data.pop()
                break;
            case "DeleteAction": //here we are undoing a delete, so putting it back
                //temporarily remove all elements in front of it
                var removedElement;
                var toPutBack = [];
                var putBackShapes = [];
                for (var i = 0; i<curAction.idxInParent; i++) {
                    console.log(curAction.everything.shapes)
                    toPutBack.push(curAction.shapeParent.data.pop());
                    putBackShapes.push(curAction.everything.shapes.pop());
                }

                //insert target
                curAction.shapeParent.data.push(curAction.target);
                curAction.everything.shapes.push(curAction.target);

                //put things back
                for (var i = 0; i<curAction.idxInParent; i++) {
                    curAction.shapeParent.data.push(toPutBack.pop())
                    curAction.everything.shapes.push(putBackShapes.pop())
                }
                break;
            case "MoveAction":
                var dX = curAction.dX;
                var dY = curAction.dY;
                var sp = curAction.target.data[0]; //Assuming target is a Shape containing a ShapePath
                sp.startX -= dX;
                sp.startY -=dY;
                for (var pathEle of sp.pathElements) {
                    pathEle.x-=dX;
                    pathEle.y-=dY;
                }
                break;
            case "ScaleAction":
                //get max/min for x and y to calculate midpoint
                var sp = curAction.target.data[0];
                var max_pt = [sp.startX, sp.startY];
                var min_pt = [sp.startX, sp.startY];
                for (var pathEle of sp.pathElements) {
                    if (pathEle.x > max_pt[0]) {
                        max_pt[0] = pathEle.x
                    }
                    else if (pathEle.x < min_pt[0]) {
                        min_pt[0] = pathEle.x
                    }
                    if (pathEle.y > max_pt[1]) {
                        max_pt[1] = pathEle.y
                    }
                    else if (pathEle.y < min_pt[1]) {
                        min_pt[1] = pathEle.y
                    }
                }
                //calc midpoint, pull out scale factors
                var midpoint = [min_pt[0] + (max_pt[0]-min_pt[0])/2, min_pt[1]+ (max_pt[1]-min_pt[1])/2]
                var sX = 1/curAction.sX //scale by the reciprocal to undo?
                var sY = 1/curAction.sY
                //fns to find offset for point
                function dX(x) {
                    return (x-midpoint[0])*(sX-1)
                }
                function dY(y) {
                    return (y-midpoint[1])*(sY-1)
                }
                //apply offset to start and every stored coordinate
                sp.startX +=dX(sp.startX)
                sp.startY +=dY(sp.startY)
                for (var pathEle of sp.pathElements) {
                    pathEle.x += dX(pathEle.x)
                    pathEle.y += dY(pathEle.y)
                }
                break;
            
        }
    }
}