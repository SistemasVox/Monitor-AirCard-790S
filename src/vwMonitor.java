import java.awt.EventQueue;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import java.awt.event.ActionListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.ArrayList;
import java.util.List;
import java.awt.event.ActionEvent;
import java.awt.Font;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.Color;

@SuppressWarnings("serial")
public class vwMonitor extends JFrame {
	private JPanel contentPane;
	private static JTextField txt0;
	private static JTextField txt1;
	private static JTextField txt2;
	private static JTextField txt3;
	private static JTextField txt4;
	private static JTextField txt5;
	private static ArrayList<JTextField> jt = new ArrayList<>();
	// private static ArrayList<JTextField> ping = new ArrayList<>();
	private static ArrayList<String> listadeStrings = new ArrayList<>();
	private JTextField txtTime;
	private boolean continuar = true, continuar_ping = true;
	private static JTextArea txtArea;
	private static int contagem = 0;
	private JTextField ping0;
	private JTextField ping1;
	private JTextField ping2;
	private JTextField ping3;
	private Process process;
	private static JLabel lblT1;
	private static JLabel lblT2;
	private static int min = 990, med = 0, max = 0, c_s = 0;
	private static String s, ms, temp1 = "99", temp2 = "99";

	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					vwMonitor frame = new vwMonitor();
					frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	public vwMonitor() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 457, 300);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		JButton btnStart = new JButton("Come\u00E7ar");
		btnStart.setBounds(10, 228, 135, 23);
		btnStart.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (continuar) {
					new Thread(new Runnable() {
						@Override
						public void run() {
							do {
								try {
									download();
									Thread.sleep(Integer.parseInt(txtTime.getText().toString()));
									if (contagem > 3) {
										contagem = 0;
									}
									txtArea.setText("Monitorando" + (pontos(contagem)));
									contagem++;
								} catch (InterruptedException e) {
									txtArea.setText(e.getMessage());
								}
							} while (continuar);
						}
					}).start();
				} else {
					txtArea.setText("Continuar False.");
				}
			}
		});
		contentPane.setLayout(null);
		contentPane.add(btnStart);
		JButton btnStop = new JButton("Parar");
		btnStop.setBounds(155, 228, 89, 23);
		btnStop.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (continuar) {
					continuar = false;
				} else {
					continuar = true;
				}
			}
		});
		contentPane.add(btnStop);
		JButton btnExit = new JButton("Sair");
		btnExit.setBounds(353, 228, 89, 23);
		btnExit.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (process != null) {
					process.destroy();
				}
				System.exit(EXIT_ON_CLOSE);
			}
		});
		lblT1 = new JLabel("x");
		lblT1.setVerticalAlignment(SwingConstants.BOTTOM);
		lblT1.setHorizontalAlignment(SwingConstants.LEFT);
		lblT1.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblT1.setBounds(265, 64, 36, 14);
		contentPane.add(lblT1);

		lblT2 = new JLabel("x");
		lblT2.setVerticalAlignment(SwingConstants.BOTTOM);
		lblT2.setHorizontalAlignment(SwingConstants.LEFT);
		lblT2.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblT2.setBounds(265, 165, 36, 14);
		contentPane.add(lblT2);
		contentPane.add(btnExit);
		JLabel lblPower = new JLabel("Power State:");
		lblPower.setBounds(10, 39, 154, 14);
		lblPower.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblPower);
		JLabel lblTemperatura = new JLabel("Current temperature:");
		lblTemperatura.setBounds(10, 64, 154, 14);
		lblTemperatura.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblTemperatura);
		JLabel lblVoltagem = new JLabel("Current voltage:");
		lblVoltagem.setBounds(10, 89, 154, 14);
		lblVoltagem.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblVoltagem);
		JLabel lblBateriaProcetagem = new JLabel("Battery charge level:");
		lblBateriaProcetagem.setBounds(10, 114, 154, 14);
		lblBateriaProcetagem.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaProcetagem);
		JLabel lblBateriaStatus = new JLabel("Battery status:");
		lblBateriaStatus.setBounds(10, 139, 154, 14);
		lblBateriaStatus.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaStatus);
		JLabel lblBateriaTemperatura = new JLabel("Battery temperature:");
		lblBateriaTemperatura.setBounds(10, 164, 154, 14);
		lblBateriaTemperatura.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaTemperatura);
		JLabel lblTitulo = new JLabel("Monitor de Temperatura AirCard 790S");
		lblTitulo.setBounds(10, 11, 414, 14);
		lblTitulo.setFont(new Font("Times New Roman", Font.BOLD, 14));
		lblTitulo.setHorizontalAlignment(SwingConstants.CENTER);
		contentPane.add(lblTitulo);
		JLabel lblStatusApp = new JLabel("Status App:");
		lblStatusApp.setBounds(10, 203, 89, 14);
		lblStatusApp.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblStatusApp);
		txt0 = new JTextField();
		txt0.setBounds(177, 37, 86, 20);
		jt.add(txt0);
		txt0.setText("00");
		txt0.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt0.setHorizontalAlignment(SwingConstants.CENTER);
		txt0.setEditable(false);
		contentPane.add(txt0);
		txt0.setColumns(10);
		txt1 = new JTextField();
		txt1.setBounds(177, 62, 86, 20);
		jt.add(txt1);
		txt1.setText("00");
		txt1.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt1.setHorizontalAlignment(SwingConstants.CENTER);
		txt1.setEditable(false);
		txt1.setColumns(10);
		contentPane.add(txt1);
		txt2 = new JTextField();
		txt2.setBounds(177, 87, 86, 20);
		jt.add(txt2);
		txt2.setText("00");
		txt2.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt2.setHorizontalAlignment(SwingConstants.CENTER);
		txt2.setEditable(false);
		txt2.setColumns(10);
		contentPane.add(txt2);
		txt3 = new JTextField();
		txt3.setBounds(177, 112, 86, 20);
		jt.add(txt3);
		txt3.setText("00");
		txt3.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt3.setHorizontalAlignment(SwingConstants.CENTER);
		txt3.setEditable(false);
		txt3.setColumns(10);
		contentPane.add(txt3);
		txt4 = new JTextField();
		txt4.setBounds(177, 137, 86, 20);
		jt.add(txt4);
		txt4.setText("00");
		txt4.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt4.setHorizontalAlignment(SwingConstants.CENTER);
		txt4.setEditable(false);
		txt4.setColumns(10);
		contentPane.add(txt4);
		txt5 = new JTextField();
		txt5.setBounds(177, 162, 86, 20);
		jt.add(txt5);
		txt5.setText("00");
		txt5.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt5.setHorizontalAlignment(SwingConstants.CENTER);
		txt5.setEditable(false);
		txt5.setColumns(10);
		contentPane.add(txt5);
		txtTime = new JTextField();
		txtTime.setBounds(356, 203, 86, 20);
		txtTime.setText("1000");
		txtTime.setFont(new Font("Tahoma", Font.BOLD, 14));
		txtTime.setHorizontalAlignment(SwingConstants.CENTER);
		contentPane.add(txtTime);
		txtTime.setColumns(10);
		txtArea = new JTextArea();
		txtArea.setFont(new Font("Monospaced", Font.BOLD, 14));
		txtArea.setWrapStyleWord(true);
		txtArea.setLineWrap(true);
		txtArea.setEditable(false);
		txtArea.setBounds(96, 203, 250, 22);
		contentPane.add(txtArea);

		JLabel lblg = new JLabel("GoogleBR:");
		lblg.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent e) {
				if (continuar_ping) {
					continuar_ping = false;
				} else {
					continuar_ping = true;
				}
			}
		});
		lblg.setHorizontalAlignment(SwingConstants.RIGHT);
		lblg.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblg.setBounds(273, 39, 79, 14);
		contentPane.add(lblg);

		ping0 = new JTextField();
		// ping.add(ping0);
		ping0.setText("00");
		ping0.setHorizontalAlignment(SwingConstants.CENTER);
		ping0.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping0.setEditable(false);
		ping0.setColumns(10);
		ping0.setBounds(353, 37, 86, 20);
		contentPane.add(ping0);

		JLabel lblmin = new JLabel("Min:");
		lblmin.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmin.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmin.setBounds(316, 64, 36, 14);
		contentPane.add(lblmin);

		ping1 = new JTextField();
		// ping.add(ping1);
		ping1.setText("00");
		ping1.setHorizontalAlignment(SwingConstants.CENTER);
		ping1.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping1.setEditable(false);
		ping1.setColumns(10);
		ping1.setBounds(353, 62, 86, 20);
		contentPane.add(ping1);

		JLabel lblmed = new JLabel("Med:");
		lblmed.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmed.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmed.setBounds(316, 89, 36, 14);
		contentPane.add(lblmed);

		ping2 = new JTextField();
		// ping.add(ping2);
		ping2.setText("00");
		ping2.setHorizontalAlignment(SwingConstants.CENTER);
		ping2.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping2.setEditable(false);
		ping2.setColumns(10);
		ping2.setBounds(353, 87, 86, 20);
		contentPane.add(ping2);

		JButton btnNewButton = new JButton("Ping");
		btnNewButton.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				new Thread(new Runnable() {
					@Override
					public void run() {
						try {
							if (continuar_ping) {
								ping();
							} else {
								txtArea.setText("Continuar FALSE");
							}
						} catch (IOException e) {
							txtArea.setText(e.getMessage());
						}
					}
				}).start();
			}
		});
		btnNewButton.setBounds(254, 228, 89, 23);
		contentPane.add(btnNewButton);

		ping3 = new JTextField();
		// ping.add(ping3);
		ping3.setText("00");
		ping3.setHorizontalAlignment(SwingConstants.CENTER);
		ping3.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping3.setEditable(false);
		ping3.setColumns(10);
		ping3.setBounds(353, 112, 86, 20);
		contentPane.add(ping3);

		JLabel lblmax = new JLabel("Max:");
		lblmax.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmax.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmax.setBounds(316, 114, 36, 14);
		contentPane.add(lblmax);

	}

	private static void download() {
		try {
			excluirARQ();
			URL website = new URL("http://192.168.1.1/about.txt?save=about.txt");
			ReadableByteChannel rbc = Channels.newChannel(website.openStream());
			@SuppressWarnings("resource")
			FileOutputStream fos = new FileOutputStream("about.txt");
			fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
			escrever();
		} catch (Exception e) {
			txtArea.setText(e.getMessage());
		}
	}

	private static void excluirARQ() {
		if (new File("about.txt").exists()) {
			new File("about.txt").delete();
		}
	}

	private static void escrever() {
		try {
			FileReader arq = new FileReader("about.txt");
			@SuppressWarnings("resource")
			BufferedReader lerArq = new BufferedReader(arq);
			String linha = lerArq.readLine();
			listadeStrings.clear();
			while (linha != null) {
				listadeStrings.add(linha);
				linha = lerArq.readLine();
			}
			for (int i = 39; i < 45; i++) {
				String[] st = listadeStrings.get(i).split(":");
				if (i == 40 || i == 44) {
					jt.get(i - 39).setText(st[1].trim().replaceAll("[^0-9]+", "") + "°");

					if (i == 40) {
						if (!temp1.equals(st[1].trim().replaceAll("[^0-9]+", ""))) {
							if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > Integer.parseInt(temp1)) {
								lblT1.setText("+");
								// R=255
								// G=0
								// B=0
								Color color = new Color(255, 0, 0);
								txt1.setForeground(color);
								audio_Play("classic notify");
							} else {
								lblT1.setText("-");
								txt1.setForeground(new Color(0, 0, 255));
							}
							temp1 = st[1].trim().replaceAll("[^0-9]+", "");

						}
					}
					if (i == 44) {
						if (!temp2.equals(st[1].trim().replaceAll("[^0-9]+", ""))) {
							if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > Integer.parseInt(temp2)) {
								lblT2.setText("+");
								txt5.setForeground(new Color(255, 0, 0));
								audio_Play("Windows XP Battery Low");
							} else {
								lblT2.setText("-");
								txt5.setForeground(new Color(0, 0, 255));
							}
							temp2 = st[1].trim().replaceAll("[^0-9]+", "");
						}

						if (Integer.parseInt(temp2) > 40 || Integer.parseInt(temp1) > 43) {
							audio_Play("Windows XP Shutdown");
						}
					}

				} else {
					jt.get(i - 39).setText(st[1].trim());
				}
			}
		} catch (Exception e) {
			txtArea.setText(e.getMessage());
			System.out.println(e.getMessage());
		}
	}

	private static void audio_Play(String nome) {
		File f = new File("sons/" + nome + ".wav");
		new AePlayWave(f.getAbsolutePath()).start();
	}

	private String pontos(int contagem) {
		String s = "";
		for (int i = 0; i < contagem; i++) {
			s += ".";
		}
		return s;
	}

	private void ping() throws IOException {
		List<String> commands = new ArrayList<String>();
		commands.add("ping");
		commands.add("-t");
		commands.add("-l");
		commands.add("756");
		commands.add("google.com.br");

		google(commands);
	}

	private void google(List<String> commands) throws IOException {
		s = "";

		ProcessBuilder pb = new ProcessBuilder(commands);
		process = pb.start();
		BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
		while ((s = stdInput.readLine()) != null) {
			if (continuar_ping) {
				if (s.matches(".*ms.*")) {
					String[] sp = s.split(" ");
					ms = sp[sp.length - 2].substring(6, sp[sp.length - 2].length());
					ping0.setText(ms);
					minMedMax(ms);
				}
			} else {
				process.destroy();
				zerar_ping();
			}
		}

	}

	private void minMedMax(String ms2) {
		if (c_s > 60) {
			zerar_ping();
		} else {
			c_s++;
		}
		int ms_att = Integer.parseInt(ms2.substring(0, ms2.length() - 2));
		if (ms_att > max) {
			max = ms_att;
		}
		if (ms_att < min) {
			min = ms_att;
		}
		med = (ms_att + med) / 2;
		ping1.setText(min + "ms");
		ping2.setText(med + "ms");
		ping3.setText(max + "ms");
	}

	private void zerar_ping() {
		c_s = 0;
		min = 999;
		max = 0;
		med = 0;
		ping0.setText("--");
		ping1.setText("--");
		ping2.setText("--");
		ping3.setText("--");
	}
}