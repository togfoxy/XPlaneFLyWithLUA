Concept

This script sets up a small economy inside your sim and lets you operate as a sole-operator inside that economy. You, as a pilot and business owner, need to fly imaginary customers and cargo around the world withou making a financial loss. 

Framework

What is provided is not a 'game', but more of a  framework. It has templates for you to complete with whatever you would like to see in your economy. The script doesn't specify income streams - you do that. The script doesn't define expense. You do that. The script does dictate planes, missions or destinations. You do all of that.

This script provides a framework so you can make the economy anything you want it be.

How does it work

The script will track or departures and arrivals and will process your templates and manipulate the economy in the ways you specify. The script will crunch numbers and process transactions and generate reports but it's only a framework so all number crunching will happen within the parameters you specify.

Example:

When you complete a flight frmo YDPO to YYRM, the script will detect your landing and process the following:

a) assign you income according to the parameters you set in the income template
b) assign you expenses according to the parameters you set in the expenses template
c) remember those expenses at that destination airport so you will be charged the same fee next time you visit
d) update your flight log
e) update your transaction log so you can track income and expenses

As you fly to different destinations, the economy will expand and you will discover which destinations are cheap to visit and which destinations are more expensive. The economy is established by you - through the templates. You decide what the expenses are and how much they cost. You can create real-life expenses with real-life amounts or you can set your templates to be something more simplistic. The script provides the framework - you provide the creativity

Templates

There are currently two templates that control the mini-economy and one template that influences the look and feel of the transaction log.

a) income template

The income template allows you to specify multiple incomes. Attributes are:
- income description (e.g. pilot pay)
- type of income (per flight, per nm, per hour)
- income amount min and max (dollar amount)

For example, you can decide pilot wages should be $150 per hour. You can also decide that an accomodation allowence should be paid once per flight. The framework will allocate whatever income items you specify in the template.
The min/max amounts lets you introduce an element of randomness.

b) expense template

The expense template is similar to the income template. It has the following attributes:
- expense description (e.g landing fees)
- expense type (per flight, per nm, per hour)
- percentage chance of the expense being charged
- expense amount min and max (dollar amount)

For example, you can decide a fuel expense should be applied per hour of flight, and then another one-off landing fee expense as well as a small fee for oil costing between $15 -> $35 being applied 25% of the time. The framework lets you decide what expenses make sense to you and even how often those expenses are applied.


Assets

The framework conceptualises everything. Even your aircraft, passengers and carge. The script has no concept of your plane. You fly the plane that you want. It makes no difference to the script. Planes do not persist. It only has a concept of a flight. That flight has a departure, a destination, a time duration and fuel used. If you think you should be charged for fuel then you can add that to the expenses template. If you think you should be charged landing fees - use the template. If you think you should be paid per hour or per nm - put that in the template.

TIP: the script assumes, but does not enforce, you flying the same plane/model. The templates can not assign different incomes and expenses for different plane types.

In the same way the script doesn't track planes, it doesn't track passengers, cargo, airports or FBO's. They are all conceptualised via the income and expense templates. The framework will let you get paid per nm or per flight hour, but the framework can't pay you per passenger ferried. There are no passengers - just flights. Your imcomes and expenses are calculated for each flight based on attributes of that flight (distance, duration and fuel used).

Mission generator

The script is not a mission generator. The pilot (you) need to determine each flight. You need to decide what world you are establishing and fly accordingly. You can use other missinn generators in conjunction with this script. You can use FSE to give you a range of flight options and then fly those with FSE and this script active on the same flight. You can use FSE to create missions and then this script to track your income and expenses. How you decide where to fly is up to you.

Economy

The script will create a range of transactions each time you land at an airport. Those transactions are decided by you and the templates. Further more, expenses persist at each airport you land at. This means landing fees could be different at each airport. You can have some airports charge you for oil and others include it free of charge. Hanger fees can vary widely across airports. All of this can be configured in the templates. As you fly to different airports you slowly build up an economic landscape and you learn which airports are expensive to land at. This might encourage you to fly to alternate airports that are near your destination and you'll seek out routes that positively affect your bottom dollar.

Roadmap: regional expenses will fluctuate over time meaning the economic landscape is never static. It will change and your flight planning might change accordingly.

Winning

As with most open ended formats - winning is what you decide it is. The framework allows you to set up the economy that intersts you most and you can change templates at any time. Your goal might be to break even or make a huge amount of money. Perhaps you want to disover a cross-country route that will cost less than $x dollars. If you're having fun - you're winning.

Support

togfox at gmail dot com





















