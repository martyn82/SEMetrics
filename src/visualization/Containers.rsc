module visualization::Containers

import lang::java::jdt::m3::Core;

import analyze::Volume;
import analyze::Complexity;
import analyze::Duplication;
import analyze::UnitSize;

import Rank;
import Quality;

// Import to print progress.
import IO;
import DateTime;

// Import to show figures.
import vis::Figure;
import vis::Render;
import vis::KeySym;
import util::Editors;

import Relation;
import Set;
import List;

public void drawContainers(M3 model, map[loc,int] unitComplexity, map[loc,int] unitSize)
{
	//  Create complexity views
	// Get TC on @Containment for a -> Method.
	rel[loc,loc] methodContainment = { <a,b> | <a,b> <- model@containment+, isMethod(b) };
	
	str rank = "All";
	render(
		vcat([
			textfield(
				"<rank>",
				void(str s)
				{
					rank = s;
				},
				bool(str s)
				{
					return s in ["All","--","-","o","+","++"];
				}
			),
			text(
				str()
				{
					return "Currently entered: <rank>";
				},
				left()
			),
			button(
				"Show system complexity",
				void()
				{
					rel[loc,int,int] allUnits = { <u, unitComplexity[u], unitSize[u]> | loc u <- unitComplexity };
					Figure f = drawContainer(model, ( model.id : allUnits ), rank);
					render("System complexity", f);
				}
			),
			button(
				"Show package complexity",
				void()
				{
					set[loc] ps = packages(model);
					rel[loc,tuple[loc,int,int]] pms = { <p, <u, unitComplexity[u], unitSize[u]>> | <p,u> <- domainR(methodContainment, ps) };
					map[loc,rel[loc,int,int]] pmsi = index(pms);
					Figure f = drawContainer(model, pmsi, rank);
					render("Package Complexity", f);
				}
			),
			button(
				"Show class complexity",
				void()
				{
					set[loc] cs = classes(model);
					rel[loc,tuple[loc,int,int]] cms = { <c, <u, unitComplexity[u], unitSize[u]>> | <c,u> <- domainR(methodContainment, cs) };
					map[loc,rel[loc,int,int]] cmsi = index(cms);
					Figure f = drawContainer(model, cmsi, rank);
					render("Class Complexity", f);
				}
			)
		])
	);
}

private str getContainerName(M3 m, loc container)
{
	modelNames = { n | <n,container> <- m@names };	
	if (!isEmpty(modelNames))
	{
		return getOneFrom(modelNames);
	}
	else
	{
		return container.path;
	}
}

public Figure drawContainer(M3 M, map[loc, rel[loc,int,int]] cms, str rankQuery)
{
	fs = for (c <- cms)
	{
		rel[loc src, int cc, int s] mcs = cms[c];

		tuple[real low,real moder, real high,real veryHigh] rc = countRelativeComplexity(mcs);
		str rank = rankToString(getComplexityRank(rc));		
				
		append <c, rank, rc>;
	};
	
	lrel[loc c, str rank, tuple[real low,real moder, real high,real veryHigh] rc] queriedFs =
		[ f | tuple[loc c, str rank, tuple[real low,real moder, real high,real veryHigh] rc] f <- fs, rankQuery == "All" || f.rank == rankQuery]; 
	gs = for (tuple[loc c, str rank, tuple[real low,real moder, real high,real veryHigh] rc] f <- queriedFs)
	{
		str name = getContainerName(M, f.c);
		rel[loc src, int cc, int s] mcs = cms[f.c];
		int locSize = (0 | it + u.s | tuple[loc d, int c, int s] u <- mcs);
		
		Figure b = box(
			vcat([
				text("<name>"),
				box(
					hcat([
						drawComplexity(f.rc.low, 0.1, { <m.m, m.cc, m.s> | tuple[loc m, int cc, int s] m <- mcs, getComplexityRank(m.cc) == 4 }),
						drawComplexity(f.rc.moder, 0.3, { <m.m, m.cc, m.s> | tuple[loc m, int cc, int s] m <- mcs, getComplexityRank(m.cc) == 3 }),
						drawComplexity(f.rc.high, 0.7, { <m.m, m.cc, m.s> | tuple[loc m, int cc, int s] m <- mcs, getComplexityRank(m.cc) == 2 }),
						drawComplexity(f.rc.veryHigh, 1.0, { <m.m, m.cc, m.s> | tuple[loc m, int cc, int s] m <- mcs, getComplexityRank(m.cc) == 1 })
					],
						std(hresizable(false))
					)
				),
				text("Rank: <f.rank>", left()),
				text("LOC: <locSize>", left())
			])
		);
		
		append b;
	};
	
	Figure b = box(
		vcat([
			text("Complexity legend"),
			box(
				text("Container name")
			),
			box(
				grid([
					[
						text("Low"),
						box(fillColor(color("Grey", 0.1)))
					],
					[
						text("Moderate"),
						box(fillColor(color("Grey", 0.3)))
					],
					[
						text("High"),
						box(fillColor(color("Grey", 0.7)))
					],
					[
						text("Very High"),
						box(fillColor(color("Grey", 1.0)))
					]
				])
			),
			text("Rank: \<Maintainability Index\>", left()),
			text("LOC: \<# Lines of code\>", left()),
			text("Click on stacked bar to show methods with the given complexity")
		])
	);
	
	return hvcat([b] + gs);
}

public Figure drawComplexity(real pct, real transp, rel[loc src, int cc, int s] ms)
{
	return box(
		vsize(25),
		hsize(pct * 2),
		fillColor(color("Grey", transp)),
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers)
		{
			lrel[loc src, int cc, int s] mss = sort(
				ms,
				bool(tuple[loc src, int cc, int s] a, tuple[loc src, int cc, int s] b)
				{
					return a.cc < b.cc;
				}
			);
			
			render(
				"Methods",
				hvcat([ drawBox(m) | m <- mss ])
			);
			return true;
		})
	);
}

public Figure drawBox(tuple[loc src, int cc, int s] m)
{
	int r = getComplexityRank(m.cc);
	Color c = color("Grey", getTransparancy(r));
	
	return box(
		vcat([
			text("Method <m>"),
			text("Cyclomatic Complexity: <m.cc>"),
			text("LOC: <m.s>")
		]),
		fillColor(Color(){ return c; }),
		onMouseEnter(void() { c = color("Yellow", getTransparancy(r)); }),
		onMouseExit(void () { c = color("Grey", getTransparancy(r)); }),
		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers)
		{
			edit(m.src);
			return true;
		})
	);
}

public real getTransparancy(int ccRank)
{
	if (ccRank == 5) { return 0.0; }
	if (ccRank == 4) { return 0.1; }
	if (ccRank == 3) { return 0.3; }
	if (ccRank == 2) { return 0.7; }
	return 1.0;
}