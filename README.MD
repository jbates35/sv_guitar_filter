<h1> Guitar Filter in SystemVerilog </h1>
<br>
<i> Jimmy Bates, Tom Kuzma</i>
<h3> This project is creating a guitar filter for our final project in ELEX 7660 </h3><hr /><br>

This project will be applying SystemVerilog to create a variable frequency LPF and HPF to filter out a guitar audio stream. This will involve taking a first order s-domain transfer function, and using a bilinear transformation to change it into a digital filter. An important variable to take into account is our sampling frequency which will be 44.1kHz.<br><br>
With some work, this is what the graph of the digital vs analog filters look like. Since it's probably not immediately clear, the x-axis is from 20Hz-20kHz.<br>
<img src="https://i.imgur.com/uqeMbO5.jpg">
<br><br>The difference equation for this will be:
<br><br><b>y[n] = w0 * ( x[n] + x[n-1] ) - w1 * y[n-1] </b><br><br>Where:<ul><li>w0 = f/(f + fs/pi)</li><li>w1 = (f-fs/pi)/(f+fs/pi)</li></ul><p>
Now looking at the graph of the high pass filters:
<img src="https://i.imgur.com/Q1w5HoT.jpg">
<br><br>The difference equation for this will be:
<br><br><b>y[n] = w0 * ( x[n] - x[n-1] ) - w1 * y[n-1] </b><br><br>Where:<ul><li>w0 = (fs/pi)/(f + fs/pi)</li><li>w1 = (f-fs/pi)/(f+fs/pi)</li></ul><p>
It should be noted that fs/pi is just a constant, which at a sample rate of 44.1kHz, will be 14037.
<hr />
Now that we have our equations sorted out, we can look now at the block diagram for the whole system, outside the FPGA. This is our block diagram so far to take a guitar signal and convert it to something that can be filtered and played into a speaker:<br><img src="https://i.imgur.com/pBctK4J.png">
