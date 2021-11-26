package view;

import java.awt.EventQueue;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import java.awt.Font;
import javax.swing.JLabel;
import javax.swing.SwingConstants;

@SuppressWarnings("serial")
public class vwError404 extends JFrame {
	private JPanel contentPane;
	private JLabel txtTitulo;
	private JTextArea textArea;

	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					vwError404 frame = new vwError404("Test");
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	public vwError404(String erro) {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 651, 448);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		contentPane.setLayout(null);
		JButton btnSair = new JButton("Sair");
		btnSair.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				dispose();
			}
		});
		btnSair.setBounds(536, 376, 89, 23);
		contentPane.add(btnSair);
		JScrollPane scrollPane = new JScrollPane();
		scrollPane.setBounds(10, 46, 615, 324);
		contentPane.add(scrollPane);
		textArea = new JTextArea();
		textArea.setWrapStyleWord(true);
		textArea.setLineWrap(true);
		textArea.setEditable(false);
		textArea.setFont(new Font("Monospaced", Font.BOLD, 14));
		scrollPane.setViewportView(textArea);
		txtTitulo = new JLabel("Erro Exception!");
		txtTitulo.setHorizontalAlignment(SwingConstants.CENTER);
		txtTitulo.setFont(new Font("Times New Roman", Font.BOLD, 14));
		txtTitulo.setBounds(10, 11, 615, 24);
		contentPane.add(txtTitulo);
		msg(erro);
	}

	public void msg(String msg) {
		textArea.setText(msg);
	}
}