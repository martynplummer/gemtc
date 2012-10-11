/*
 * This file is part of the GeMTC software for MTC model generation and
 * analysis. GeMTC is distributed from http://drugis.org/gemtc.
 * Copyright (C) 2009-2012 Gert van Valkenhoef.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.drugis.mtc;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.xml.bind.JAXBException;

import org.apache.commons.math3.random.JDKRandomGenerator;
import org.drugis.mtc.data.DataType;
import org.drugis.mtc.jags.JagsSyntaxModel;
import org.drugis.mtc.model.JAXBHandler;
import org.drugis.mtc.model.Network;
import org.drugis.mtc.model.Study;
import org.drugis.mtc.model.Treatment;
import org.drugis.mtc.parameterization.AbstractDataStartingValueGenerator;
import org.drugis.mtc.parameterization.BasicParameter;
import org.drugis.mtc.parameterization.ConsistencyParameterization;
import org.drugis.mtc.parameterization.InconsistencyParameterization;
import org.drugis.mtc.parameterization.NetworkModel;
import org.drugis.mtc.parameterization.NodeSplitParameterization;
import org.drugis.mtc.parameterization.Parameterization;
import org.drugis.mtc.parameterization.StartingValueGenerator;

import edu.uci.ics.jung.algorithms.transformation.FoldingTransformerFixed.FoldedEdge;
import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.util.Pair;

public class JagsGenerator {
	private final Options d_options;

	public JagsGenerator(Options options) {
		d_options = options;
	}
	
	public void run() throws FileNotFoundException, JAXBException {
		Network network = JAXBHandler.readNetwork(new FileInputStream(d_options.getXmlFile()));
		generateModel(network);
	}

	private void generateModel(Network network) throws FileNotFoundException {
		for (ModelSpecification spec : createJagsModels(network)) {
			writeModel(spec);
		}
	}

	private List<ModelSpecification> createJagsModels(Network network) {
		switch (d_options.getModelType()) {
		case CONSISTENCY:
			ConsistencyParameterization cons = ConsistencyParameterization.create(network);
			return Collections.singletonList(createJagsModel(network, cons, ".cons"));
		case INCONSISTENCY:
			InconsistencyParameterization inco = InconsistencyParameterization.create(network);
			return Collections.singletonList(createJagsModel(network, inco, ".inco"));
		case NODESPLIT:
			List<ModelSpecification> list = new ArrayList<ModelSpecification>();
			for (BasicParameter p : NodeSplitParameterization.getSplittableNodes(NetworkModel.createStudyGraph(network), NetworkModel.createComparisonGraph(network))) {
				NodeSplitParameterization splt = NodeSplitParameterization.create(network, p);
				list.add(createJagsModel(network, splt, ".splt." + p.getBaseline().getId() + "." + p.getSubject().getId()));
			}
			return list;
		default:
			throw new IllegalArgumentException("Unknown model type " + d_options.getModelType());
		}
	}

	private ModelSpecification createJagsModel(Network network, Parameterization pmtz, String suffix) {
		if (!isSupported(network.getType())) {
			return new ModelSpecification(network, pmtz, null, null, suffix);
		}
		final JagsSyntaxModel model = new JagsSyntaxModel(network, pmtz, !d_options.getBugsOutput());
		final StartingValueGenerator generator = AbstractDataStartingValueGenerator.create(
				network, NetworkModel.createComparisonGraph(network), 
				new JDKRandomGenerator(), d_options.getScale());
		return new ModelSpecification(network, pmtz, model, generator, suffix);
	}

	private boolean isSupported(DataType type) {
		return DataType.RATE.equals(type) || DataType.CONTINUOUS.equals(type);
	}
	
	private void printGraph(Graph<Treatment, FoldedEdge<Treatment, Study>> g) {
		System.out.println("\tgraph {");
		for (FoldedEdge<Treatment, Study> e : g.getEdges()) {
			Pair<Treatment> t = new Pair<Treatment>(g.getIncidentVertices(e));
			System.out.println("\t\t" + t.getFirst().getId() + " -- " + t.getSecond().getId());
		}
		System.out.println("\t}");
	}
	
	public void writeModel(ModelSpecification spec) throws FileNotFoundException {
		boolean suppress = false;
		if (d_options.getSuppressOutput()) {
			System.out.println("Detected --suppress, not generating a model.");
			suppress = true;
		} else if (spec.getModel() == null) {
			System.out.println("Unsupported measurement type, not generating a model.");
			suppress = true;
		}
		printStructure(NetworkModel.createComparisonGraph(spec.getNetwork()), spec.getParameterization().getBasicParameterTree());

		if (suppress) {
			return;
		}

		System.out.println("Writing JAGS scripts: " + d_options.getBaseName() + spec.getNameSuffix() + ".*");

		PrintStream dataOut = new PrintStream(d_options.getBaseName() + spec.getNameSuffix() + ".data");
		dataOut.println(spec.getModel().dataText());
		dataOut.close();

		PrintStream modelOut = new PrintStream(d_options.getBaseName() + spec.getNameSuffix() + ".model");
		modelOut.println(spec.getModel().modelText());
		modelOut.close();

		int nChains = 4;

		PrintStream scriptOut = new PrintStream(d_options.getBaseName() + spec.getNameSuffix() + ".script");
		scriptOut.println(spec.getModel().scriptText(d_options.getBaseName() + spec.getNameSuffix(), nChains,
				d_options.getTuningIterations(), d_options.getSimulationIterations()));
		scriptOut.close();

		for (int i = 0; i < nChains; ++i) {
			PrintStream paramOut = new PrintStream(d_options.getBaseName() + spec.getNameSuffix() + ".inits" + (i + 1));
			paramOut.println(spec.getModel().initialValuesText(spec.getGenerator()));
			paramOut.close();
		}

		if (d_options.getModelType() != ModelType.NODESPLIT) { // FIXME: implement for nodesplit
			PrintStream analysisOut = new PrintStream(d_options.getBaseName() + spec.getNameSuffix() + ".analysis.R");
			analysisOut.println(spec.getModel().analysisText(d_options.getBaseName() + spec.getNameSuffix()));
			analysisOut.close();
		}
	}

	private void printStructure(
			final Graph<Treatment, FoldedEdge<Treatment, Study>> comparisonGraph,
			final Graph<Treatment, FoldedEdge<Treatment, Study>> tree) {
		System.out.println("Comparison graph: ");
		printGraph(comparisonGraph);
		System.out.println("Basic parameters: ");
		printGraph(tree);
	}
}