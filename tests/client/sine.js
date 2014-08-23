var canvas = document.getElementById("canvas");
var ctx = canvas.getContext("2d");



var points = {}; 
var x = 0;
var len = 500;

animate();


function animate() {
    requestAnimationFrame( animate );
    draw();
}

function y() {
    var mag = 20;
    var angle = 0.15;
    return mag * Math.sin(angle * x) + len/2;
}

function draw(){
    ctx.clearRect(0, 0, len, len); // Clear the canvas
    ctx.beginPath();
    ctx.setLineWidth(3);
    ctx.setStrokeColor("blue");
    points[x] = y();
    x += 1;
    for(var i = 0; i < len; i++) {
        ctx.lineTo(i, points[i + x - len]);
    }
    ctx.stroke();
}
