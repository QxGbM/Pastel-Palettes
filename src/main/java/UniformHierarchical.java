
import Jama.Matrix;
import java.io.*;

public class UniformHierarchical implements Block {

  private ClusterBasis row_basis;
  private Block e[][];
  private int x_start = 0;
  private int y_start = 0;

  public UniformHierarchical (int m, int n) {
    e = new Block[m][n];
    row_basis = null;
  }

  public UniformHierarchical (Dense d, ClusterBasis upper_basis, int m, int n, int sample_rank, int min_block_size) {
    e = new Block[m][n];
    Hierarchical h = d.toHierarchical(m, n);
    ClusterBasis lower_basis[] = upper_basis.hasChildren() ? upper_basis.getChildren() : new ClusterBasis[m];

    for (int i = 0; i < m; i++) {

      ClusterBasis basis;
      if (upper_basis.hasChildren()) {
        basis = lower_basis[i];
      }
      else {
        basis = i == 0 ? 
          new ClusterBasis(h.getElement(i, 1).toDense(), sample_rank) : 
          new ClusterBasis(h.getElement(i, 0).toDense(), sample_rank);
      }

      Matrix basis_m = basis.toMatrix();

      for (int j = 0; j < n; j++) {
        Dense d_ij = h.getElement(i, j).toDense();
        Matrix t = basis_m.transpose().times(d_ij);
        double err = basis_m.times(t).minus(d_ij).normF() / d_ij.getRowDimension() / d_ij.getColumnDimension();

        if (err <= 1.e-12) {
          e[i][j] = new LowRank(basis_m, t.transpose());
        }
        else if (d_ij.getRowDimension() <= min_block_size && d_ij.getColumnDimension() <= min_block_size) {
          e[i][j] = new Dense(d_ij.getArray());
        }
        else {
          UniformHierarchical uh = new UniformHierarchical(d_ij, basis, m, n, sample_rank, min_block_size);
          e[i][j] = uh; basis = uh.getRowBasis();
        }
      }

      lower_basis[i] = basis;
    }

    if (!upper_basis.hasChildren()) {
      upper_basis.setChildren(lower_basis);
    }
    row_basis = upper_basis;
  }

  public UniformHierarchical (Dense d, int m, int n, int sample_rank, int min_block_size) {
    this(d, new ClusterBasis(), m, n, sample_rank, min_block_size);
    row_basis.convertTrans_children();
  }

  @Override
  public int getXCenter() {
    return x_start + getRowDimension() / 2;
  }

  @Override
  public int getYCenter() {
    return y_start + getColumnDimension() / 2;
  }

  @Override
  public void setClusterStart (int x_start, int y_start) {
    this.x_start = x_start;
    this.y_start = y_start;
  }

  public int getNRowBlocks()
  { return e.length; }

  public int getNColumnBlocks()
  { return e[0].length; }

  public ClusterBasis getRowBasis() {
    return row_basis;
  }

  @Override
  public int getRowDimension() {
    int accum = 0;
    for (int i = 0; i < getNRowBlocks(); i++)
    { accum += e[i][0].getRowDimension(); }
    return accum;
  }

  @Override
  public int getColumnDimension() {
    int accum = 0;
    for (int i = 0; i < getNColumnBlocks(); i++)
    { accum += e[0][i].getColumnDimension(); }
    return accum;
  }

  @Override
  public Block_t getType() {
    return Block_t.HIERARCHICAL;
  }
  
  @Override
  public Dense toDense() {
    Dense d = new Dense(getRowDimension(), getColumnDimension());
    int i0 = 0;

    for (int i = 0; i < getNRowBlocks(); i++) {
      int i1 = 0, j0 = 0;
      for (int j = 0; j < getNColumnBlocks(); j++) {
        Dense X = e[i][j].toDense(); 
        int j1 = j0 + X.getColumnDimension() - 1;
        i1 = i0 + X.getRowDimension() - 1;
        d.setMatrix(i0, i1, j0, j1, X);
        j0 = j1 + 1;
      }
      i0 = i1 + 1;
    }

    return d;
  }

  @Override
  public LowRank toLowRank() {
    return null;
  }

  @Override
  public Hierarchical toHierarchical (int m, int n) {
    return null;
  }

  @Override
  public Hierarchical toHierarchical (int level, int m, int n) {
    return null;
  }

  @Override
  public boolean testAdmis (Matrix row_basis, Matrix col_basis, double admis_cond) {
    return false;
  }

  @Override
  public boolean equals (Block b) {
    return false;
  }

  @Override
  public double getCompressionRatio () {
    return 0;
  }

  @Override
  public String structure () {
    return null;
  }

  @Override
  public void loadBinary (InputStream stream) throws IOException {
    
  }

  @Override
  public void writeBinary (OutputStream stream) throws IOException {

  }

  @Override
  public void writeToFile (String name) throws IOException {

  }

  @Override
  public void print (int w, int d) {

  }

  @Override
  public void LU () {
    
  }

  @Override
  public void triangularSolve (Block b, boolean up_low) {

  }

  @Override
  public void GEMatrixMult (Block a, Block b, double alpha, double beta) {

  }

}